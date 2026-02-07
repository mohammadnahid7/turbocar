# Chat System Refactor Roadmap

This document outlines the plan to refactor the current chat system to match the enterprise-level architecture defined in `MARKETPLACE_CHAT_ARCHITECTURE.md`.

## 1. Current State & Gap Analysis

### 1.1. Core Concept Mismatch
- **Current:** generic User-to-User chat. A user can only have *one* conversation with another user, regardless of context.
- **Target:** Contextual User-to-Seller chat about a specific **Car**. A buyer can have multiple conversations with the same seller if they are about different cars.

### 1.2. Database Schema Gaps
| Feature | Current Implementation | Target Architecture | Gap |
|---------|------------------------|---------------------|-----|
| **Context** | No `car_id` connection | `car_id` (UUID) column | **CRITICAL**: Need to add `car_id` to conversations |
| **Denormalization** | None | `car_title`, `car_seller_id` | Missing columns for performance |
| **JSONB** | `map[string]interface{}` (Raw) | Custom `Metadata` type | **BUG**: Causes scan errors. Need `Value()`/`Scan()` |
| **Participants** | `ConversationParticipant` struct | Same concept | Mostly aligned, need checking unique constraints |
| **Messages** | `MediaURL` field | `AttachmentURL` | Minor naming difference |

### 1.3. Code Gaps
- **Models:** incorrectly typed JSONB field. Missing `CarID` fields.
- **Repository:** `GetConversationBetweenUsers` is insufficient for car-contextual chat. Need `FindOrCreateConversation(carID, buyerID, sellerID)`.
- **Service:** Logic currently assumes 1-on-1 user uniqueness.

---

## 2. Migration Strategy

**Selected Strategy: Gradual Migration (Option B)**

Since the current system is already attempting to work (but failing on JSONB), we will fix the immediate bugs first, then incrementally add the "Car Context" features.

### Phase 1: Fix JSONB Scanning (Immediate Fix) 🚨
**Goal:** Stop the runtime errors so the current app works, even if imperfect.
1.  Create `internal/chat/types.go` with `Metadata` type implementing `Scanner` and `Valuer`.
2.  Update `Conversation` struct in `models.go` to use `Metadata` type.
3.  **Verification:** Chat works without 500 errors.

### Phase 2: Schema Migration & Model Updates
**Goal:** Add necessary columns for Car Context.
1.  Create SQL migration:
    *   Add `car_id` (UUID, nullable for now).
    *   Add `car_title` (String).
    *   Add `car_seller_id` (UUID).
    *   Add `last_message_at` (Timestamp).
2.  Run migration.
3.  Update `Conversation` struct in `models.go`.

### Phase 3: Repository Refactoring
**Goal:** Implement "Car Context" query logic.
1.  Update `CreateConversation` to accept `carID`, `carTitle`, `sellerID`.
2.  Implement `FindOrCreateConversation` checking `car_id` + `buyer_id`.
3.  Update `GetUserConversations` to join/select new fields.

### Phase 4: Service & Handler Updates
**Goal:** Connect API to new logic.
1.  Update `StartConversationRequest` DTO to require `car_id`.
2.  Update `Service.StartConversation` to use new Repository methods.
3.  Ensure backward compatibility (if `car_id` missing, maybe handle gracefully or error if strict).

---

## 3. Implementation Steps

### Step 1: Fix JSONB (Types)
- **File:** `internal/chat/types.go` (NEW)
- **Content:**
```go
package chat

import (
    "database/sql/driver"
    "encoding/json"
    "errors"
)

type Metadata map[string]interface{}

func (m Metadata) Value() (driver.Value, error) {
    if m == nil {
        return json.Marshal(map[string]interface{}{})
    }
    return json.Marshal(m)
}

func (m *Metadata) Scan(value interface{}) error {
    if value == nil {
        *m = make(Metadata)
        return nil
    }
    bytes, ok := value.([]byte)
    if !ok {
        return errors.New("failed to unmarshal JSONB value")
    }
    return json.Unmarshal(bytes, &m)
}
```

### Step 2: Update Models
- **File:** `internal/chat/models.go`
- **Change:** Replace `map[string]interface{}` with `Metadata`. Add `CarID`, `CarTitle`, `CarSellerID`.

### Step 3: Update DTOs
- **File:** `internal/chat/dto.go`
- **Change:** Add `CarID` to `StartConversationRequest`.

---

## 4. Testing Plan

### 4.1. Manual Verification
1.  **Start Chat:** Send POST `/api/chat/conversations` with `car_id`.
2.  **Verify DB:** Check `conversations` table has `car_id` set and `metadata` is valid JSON.
3.  **List Chats:** Call GET `/api/chat/conversations` and ensure duplicates don't appear for same car/user pair.
4.  **Messaging:** Send message, checks `last_message_at` updates.

### 4.2. Automated Tests
- Run `go test ./internal/chat/...` (Create new tests for `FindOrCreateConversation`).
