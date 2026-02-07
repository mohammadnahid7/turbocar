# Enterprise-Level Chat System Architecture for Car Marketplace
## PostgreSQL Database Design

> **Context**: Car selling marketplace where buyers can initiate conversations with sellers about specific vehicles. Each conversation is contextual to a car listing and involves two participants (buyer and seller).

---

## 🎯 Design Philosophy

### Core Principles
1. **Simplicity First**: Marketplace chat is simpler than general messaging apps - it's always 1-on-1 and car-contextual
2. **Hybrid Schema**: Use traditional columns for frequently queried data, JSONB only for truly variable metadata
3. **Query Efficiency**: Design schema to minimize joins and avoid N+1 problems
4. **Scalability**: Plan for millions of messages, thousands of concurrent conversations
5. **Data Integrity**: Strong foreign keys, proper constraints, and transactional safety

---

## 📊 Database Schema

### Table 1: `conversations`

**Purpose**: Tracks each unique conversation between a buyer and seller about a specific car.

```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Car context (denormalized for performance)
    car_id UUID NOT NULL,
    car_title VARCHAR(255) NOT NULL,  -- Denormalized: avoid join on every query
    car_seller_id UUID NOT NULL,      -- Denormalized: quick access control checks
    
    -- Conversation state
    status VARCHAR(20) NOT NULL DEFAULT 'active',  -- active, archived, blocked
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at TIMESTAMPTZ,  -- For sorting conversations by recency
    
    -- Optional metadata (use sparingly!)
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Constraints
    CONSTRAINT valid_status CHECK (status IN ('active', 'archived', 'blocked'))
);

-- Critical indexes
CREATE INDEX idx_conversations_car_id ON conversations(car_id);
CREATE INDEX idx_conversations_seller ON conversations(car_seller_id);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);

-- Composite index for common query: "find conversation for this car and seller"
CREATE INDEX idx_conversations_car_seller ON conversations(car_id, car_seller_id);
```

**Why This Design:**
- `car_title` is denormalized because we show it in conversation lists - avoids JOIN with cars table
- `car_seller_id` is denormalized for quick authorization checks ("does this user own this conversation?")
- `last_message_at` enables efficient "sort by recent activity" without joining messages table
- `metadata` JSONB is available but discouraged - use only for truly optional/variable data

**Metadata Usage Guidelines:**
```jsonb
{
  "car_price": 25000,           // If you want to show price at time of conversation start
  "car_thumbnail_url": "...",   // Snapshot of car image URL
  "archived_reason": "sold",    // Why conversation was archived
  "tags": ["urgent", "vip"]     // Optional user-defined tags
}
```

---

### Table 2: `conversation_participants`

**Purpose**: Links users to conversations (enables quick lookups like "all conversations for this user").

```sql
CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    
    -- Read tracking
    last_read_message_id UUID,  -- NULL means never read, references messages(id)
    unread_count INTEGER NOT NULL DEFAULT 0,
    
    -- Participant metadata
    role VARCHAR(20) NOT NULL,  -- 'buyer' or 'seller'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Unique constraint: each user can only be in a conversation once
    CONSTRAINT unique_participant UNIQUE(conversation_id, user_id)
);

-- Critical indexes
CREATE INDEX idx_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_participants_unread ON conversation_participants(user_id, unread_count) 
    WHERE unread_count > 0;  -- Partial index for efficiency

-- Constraint check
ALTER TABLE conversation_participants 
    ADD CONSTRAINT valid_role CHECK (role IN ('buyer', 'seller'));
```

**Why This Design:**
- Simple join table - no over-engineering
- `unread_count` is denormalized for performance (updated via trigger or application logic)
- `role` helps distinguish buyer from seller in UI
- Partial index on `unread_count > 0` makes "show conversations with unread messages" very fast
- `last_read_message_id` enables precise "read up to here" tracking

---

### Table 3: `messages`

**Purpose**: Stores all messages in all conversations.

```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    
    -- Message content
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    
    -- Message type and state
    message_type VARCHAR(20) NOT NULL DEFAULT 'text',  -- text, image, offer, system
    status VARCHAR(20) NOT NULL DEFAULT 'sent',        -- sent, delivered, read, deleted
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,  -- For edited messages
    deleted_at TIMESTAMPTZ,  -- Soft delete
    
    -- Optional attachments (if needed)
    attachment_url TEXT,
    attachment_type VARCHAR(50),
    
    -- Reply threading (optional)
    reply_to_message_id UUID REFERENCES messages(id),
    
    -- Constraints
    CONSTRAINT valid_message_type CHECK (message_type IN ('text', 'image', 'offer', 'system')),
    CONSTRAINT valid_status CHECK (status IN ('sent', 'delivered', 'read', 'deleted'))
);

-- Critical indexes
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- Partial index for active messages (excludes deleted)
CREATE INDEX idx_messages_active ON messages(conversation_id, created_at DESC) 
    WHERE deleted_at IS NULL;
```

**Why This Design:**
- Simple, normalized structure - messages are just messages
- `conversation_id + created_at DESC` index is perfect for "load last 50 messages" query
- `deleted_at` enables soft delete without losing conversation history
- `message_type` allows special messages like "Seller sent a price offer: $20,000"
- `attachment_url` handles images/files - no separate table needed for marketplace chat
- `reply_to_message_id` enables threading if you want to add that feature later

---

## 🚀 Common Query Patterns

### 1. Find or Create Conversation

```sql
-- Step 1: Try to find existing conversation
SELECT c.id, c.car_title, c.last_message_at
FROM conversations c
WHERE c.car_id = $1 
  AND c.car_seller_id = $2
  AND EXISTS (
    SELECT 1 FROM conversation_participants cp
    WHERE cp.conversation_id = c.id 
      AND cp.user_id = $3  -- buyer_id
  )
LIMIT 1;

-- Step 2: If not found, create new conversation (in a transaction)
BEGIN;

INSERT INTO conversations (car_id, car_title, car_seller_id, metadata)
VALUES ($1, $2, $3, $4)
RETURNING id;

INSERT INTO conversation_participants (conversation_id, user_id, role)
VALUES 
    ($conversation_id, $buyer_id, 'buyer'),
    ($conversation_id, $seller_id, 'seller');

COMMIT;
```

**Why**: This is atomic and handles race conditions. The EXISTS clause ensures we only get conversations where the buyer is a participant.

---

### 2. Get User's Conversation List

```sql
SELECT 
    c.id,
    c.car_id,
    c.car_title,
    c.last_message_at,
    cp.unread_count,
    cp.last_read_message_id,
    -- Get the other participant (the person user is chatting with)
    other_cp.user_id as other_user_id,
    other_cp.role as other_user_role,
    -- Get last message preview
    m.content as last_message_content,
    m.sender_id as last_message_sender_id,
    m.created_at as last_message_time
FROM conversations c
INNER JOIN conversation_participants cp 
    ON cp.conversation_id = c.id
INNER JOIN conversation_participants other_cp 
    ON other_cp.conversation_id = c.id 
    AND other_cp.user_id != $1
LEFT JOIN LATERAL (
    SELECT content, sender_id, created_at
    FROM messages
    WHERE conversation_id = c.id 
      AND deleted_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1
) m ON true
WHERE cp.user_id = $1
  AND c.status = 'active'
ORDER BY c.last_message_at DESC NULLS LAST
LIMIT 50 OFFSET $2;
```

**Why**: Single query gets everything needed for conversation list UI:
- Conversation details
- Unread count
- Last message preview
- Other participant info (to show their name/avatar)

---

### 3. Get Messages with Pagination

```sql
SELECT 
    id,
    sender_id,
    content,
    message_type,
    status,
    created_at,
    attachment_url,
    attachment_type,
    reply_to_message_id
FROM messages
WHERE conversation_id = $1
  AND deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 50 OFFSET $2;
```

**Why**: Simple, uses the composite index perfectly. Always paginate messages - don't load entire conversation history.

---

### 4. Send Message (Transaction)

```sql
BEGIN;

-- Insert the message
INSERT INTO messages (conversation_id, sender_id, content, message_type)
VALUES ($1, $2, $3, $4)
RETURNING id, created_at;

-- Update conversation's last_message_at
UPDATE conversations 
SET last_message_at = NOW(),
    updated_at = NOW()
WHERE id = $1;

-- Increment unread count for recipient(s)
UPDATE conversation_participants
SET unread_count = unread_count + 1
WHERE conversation_id = $1
  AND user_id != $2;  -- Don't increment for sender

COMMIT;
```

**Why**: All updates in one transaction ensures consistency. The unread count is updated immediately.

---

### 5. Mark Messages as Read

```sql
UPDATE conversation_participants
SET last_read_message_id = $1,
    unread_count = 0
WHERE conversation_id = $2
  AND user_id = $3;
```

**Why**: Simple update. The `$1` is the latest message ID that the user has seen.

---

## 🎨 JSONB Metadata: When and How

### ❌ ANTI-PATTERNS (Don't Do This)

```sql
-- BAD: Storing everything in JSONB
CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    data JSONB  -- Contains car_id, car_title, seller_id, buyer_id, messages, etc.
);
```

**Problems:**
- PostgreSQL can't gather statistics on JSONB fields → poor query planning
- 2x storage space compared to normalized columns
- Slower queries (even with GIN indexes)
- Can't create foreign keys on JSONB fields
- Updates require full document rewrite

### ✅ CORRECT USAGE (Hybrid Approach)

```sql
-- GOOD: Core fields as columns, optional metadata in JSONB
CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    car_id UUID NOT NULL,          -- Column: always queried
    car_title VARCHAR NOT NULL,    -- Column: always displayed
    car_seller_id UUID NOT NULL,   -- Column: used in WHERE clauses
    created_at TIMESTAMPTZ NOT NULL,
    
    -- JSONB only for truly optional, variable data
    metadata JSONB DEFAULT '{}'::jsonb
);

-- If you need to query inside metadata, add GIN index
CREATE INDEX idx_conversations_metadata_gin ON conversations USING GIN (metadata);

-- Or index specific paths if you query them frequently
CREATE INDEX idx_conversations_price ON conversations ((metadata->>'car_price'));
```

### JSONB Best Practices

1. **Use GIN Indexes for Containment Queries**
```sql
-- Query: Find conversations with specific metadata
SELECT * FROM conversations 
WHERE metadata @> '{"archived_reason": "sold"}'::jsonb;

-- Requires GIN index
CREATE INDEX idx_conversations_metadata ON conversations USING GIN (metadata);
```

2. **Use Expression Indexes for Specific Fields**
```sql
-- If you frequently filter by a specific metadata field
CREATE INDEX idx_metadata_price ON conversations 
    ((metadata->>'car_price')::numeric)
WHERE metadata->>'car_price' IS NOT NULL;
```

3. **Keep JSONB Small**
- Never store arrays with thousands of elements
- Avoid deeply nested structures (max 3-4 levels)
- PostgreSQL TOAST compression kicks in at 2KB - try to stay under that

4. **Use JSONB Functions Correctly**
```sql
-- WRONG: String comparison on numeric field
WHERE metadata->>'price' > '10000'  -- Compares as strings!

-- CORRECT: Cast to appropriate type
WHERE (metadata->>'price')::numeric > 10000
```

---

## 🔧 Go/GORM Implementation Patterns

### Custom JSONB Type (Scanner/Valuer)

```go
package models

import (
    "database/sql/driver"
    "encoding/json"
    "errors"
)

// Metadata represents flexible JSONB data
type Metadata map[string]interface{}

// Value implements driver.Valuer interface for GORM
func (m Metadata) Value() (driver.Value, error) {
    if m == nil {
        return json.Marshal(map[string]interface{}{})
    }
    return json.Marshal(m)
}

// Scan implements sql.Scanner interface for GORM
func (m *Metadata) Scan(value interface{}) error {
    if value == nil {
        *m = make(Metadata)
        return nil
    }

    bytes, ok := value.([]byte)
    if !ok {
        return errors.New("failed to unmarshal JSONB value")
    }

    result := make(Metadata)
    if err := json.Unmarshal(bytes, &result); err != nil {
        return err
    }

    *m = result
    return nil
}
```

### Model Definitions

```go
type Conversation struct {
    ID            string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    CarID         string    `gorm:"type:uuid;not null;index:idx_car"`
    CarTitle      string    `gorm:"type:varchar(255);not null"`
    CarSellerID   string    `gorm:"type:uuid;not null;index:idx_seller"`
    Status        string    `gorm:"type:varchar(20);not null;default:active"`
    CreatedAt     time.Time `gorm:"not null;default:now()"`
    UpdatedAt     time.Time `gorm:"not null;default:now()"`
    LastMessageAt *time.Time `gorm:"index:idx_last_message"`
    
    // Custom JSONB type
    Metadata      Metadata  `gorm:"type:jsonb;default:'{}'"`
    
    // Relationships (use preload carefully!)
    Participants  []ConversationParticipant `gorm:"foreignKey:ConversationID"`
    Messages      []Message                 `gorm:"foreignKey:ConversationID"`
}

type ConversationParticipant struct {
    ID                 string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    ConversationID     string    `gorm:"type:uuid;not null;index:idx_conversation"`
    UserID             string    `gorm:"type:uuid;not null;index:idx_user"`
    LastReadMessageID  *string   `gorm:"type:uuid"`
    UnreadCount        int       `gorm:"not null;default:0"`
    Role               string    `gorm:"type:varchar(20);not null"`
    JoinedAt           time.Time `gorm:"not null;default:now()"`
}

type Message struct {
    ID              string     `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
    ConversationID  string     `gorm:"type:uuid;not null;index:idx_conversation_time,priority:1"`
    SenderID        string     `gorm:"type:uuid;not null;index:idx_sender"`
    Content         string     `gorm:"type:text;not null"`
    MessageType     string     `gorm:"type:varchar(20);not null;default:text"`
    Status          string     `gorm:"type:varchar(20);not null;default:sent"`
    CreatedAt       time.Time  `gorm:"not null;default:now();index:idx_conversation_time,priority:2,sort:desc"`
    UpdatedAt       *time.Time
    DeletedAt       *time.Time `gorm:"index:idx_active"`
    AttachmentURL   *string    `gorm:"type:text"`
    AttachmentType  *string    `gorm:"type:varchar(50)"`
}
```

### Repository Pattern (Efficient Queries)

```go
package repository

type ChatRepository struct {
    db *gorm.DB
}

// FindOrCreateConversation - Atomic operation
func (r *ChatRepository) FindOrCreateConversation(
    carID, carTitle, sellerID, buyerID string,
) (*Conversation, bool, error) {
    var conv Conversation
    
    // Try to find existing
    err := r.db.
        Where("car_id = ? AND car_seller_id = ?", carID, sellerID).
        Where(`EXISTS (
            SELECT 1 FROM conversation_participants 
            WHERE conversation_id = conversations.id 
            AND user_id = ?
        )`, buyerID).
        First(&conv).Error
    
    if err == nil {
        return &conv, false, nil // Found existing
    }
    
    if !errors.Is(err, gorm.ErrRecordNotFound) {
        return nil, false, err // Actual error
    }
    
    // Create new conversation in transaction
    err = r.db.Transaction(func(tx *gorm.DB) error {
        conv = Conversation{
            CarID:       carID,
            CarTitle:    carTitle,
            CarSellerID: sellerID,
            Metadata:    Metadata{},
        }
        
        if err := tx.Create(&conv).Error; err != nil {
            return err
        }
        
        participants := []ConversationParticipant{
            {ConversationID: conv.ID, UserID: buyerID, Role: "buyer"},
            {ConversationID: conv.ID, UserID: sellerID, Role: "seller"},
        }
        
        return tx.Create(&participants).Error
    })
    
    return &conv, true, err
}

// GetUserConversations - Optimized single query
func (r *ChatRepository) GetUserConversations(
    userID string, 
    limit, offset int,
) ([]ConversationListItem, error) {
    var results []ConversationListItem
    
    err := r.db.Raw(`
        SELECT 
            c.id,
            c.car_id,
            c.car_title,
            c.last_message_at,
            cp.unread_count,
            other_cp.user_id as other_user_id,
            other_cp.role as other_user_role,
            m.content as last_message_content,
            m.sender_id as last_message_sender_id,
            m.created_at as last_message_time
        FROM conversations c
        INNER JOIN conversation_participants cp 
            ON cp.conversation_id = c.id
        INNER JOIN conversation_participants other_cp 
            ON other_cp.conversation_id = c.id 
            AND other_cp.user_id != ?
        LEFT JOIN LATERAL (
            SELECT content, sender_id, created_at
            FROM messages
            WHERE conversation_id = c.id 
              AND deleted_at IS NULL
            ORDER BY created_at DESC
            LIMIT 1
        ) m ON true
        WHERE cp.user_id = ?
          AND c.status = 'active'
        ORDER BY c.last_message_at DESC NULLS LAST
        LIMIT ? OFFSET ?
    `, userID, userID, limit, offset).
    Scan(&results).Error
    
    return results, err
}

// SendMessage - Atomic operation
func (r *ChatRepository) SendMessage(
    conversationID, senderID, content string,
) (*Message, error) {
    var message Message
    
    err := r.db.Transaction(func(tx *gorm.DB) error {
        // Insert message
        message = Message{
            ConversationID: conversationID,
            SenderID:       senderID,
            Content:        content,
            MessageType:    "text",
        }
        
        if err := tx.Create(&message).Error; err != nil {
            return err
        }
        
        // Update conversation timestamp
        if err := tx.Model(&Conversation{}).
            Where("id = ?", conversationID).
            Updates(map[string]interface{}{
                "last_message_at": time.Now(),
                "updated_at":      time.Now(),
            }).Error; err != nil {
            return err
        }
        
        // Increment unread for recipients
        return tx.Model(&ConversationParticipant{}).
            Where("conversation_id = ? AND user_id != ?", conversationID, senderID).
            Update("unread_count", gorm.Expr("unread_count + ?", 1)).
            Error
    })
    
    return &message, err
}

// GetMessages - Simple paginated query
func (r *ChatRepository) GetMessages(
    conversationID string,
    limit, offset int,
) ([]Message, error) {
    var messages []Message
    
    err := r.db.
        Where("conversation_id = ? AND deleted_at IS NULL", conversationID).
        Order("created_at DESC").
        Limit(limit).
        Offset(offset).
        Find(&messages).Error
    
    return messages, err
}
```

---

## 🎯 Performance Optimization Checklist

### 1. **Indexing Strategy**
- ✅ Index all foreign keys
- ✅ Composite index on `(conversation_id, created_at DESC)` for messages
- ✅ Index on `last_message_at` for conversation sorting
- ✅ Partial index on `unread_count > 0` for notification queries
- ✅ GIN index on JSONB only if you actually query inside it

### 2. **Query Optimization**
- ✅ Use `LIMIT` on all message queries
- ✅ Avoid `SELECT *` - specify columns explicitly
- ✅ Use `EXISTS` instead of `COUNT` for presence checks
- ✅ Use `LATERAL JOIN` for "get last message" efficiently
- ✅ Batch operations in transactions

### 3. **GORM Best Practices**
- ✅ Never use `Preload` for messages - always paginate
- ✅ Use raw SQL for complex joins
- ✅ Implement custom Scanner/Valuer for JSONB
- ✅ Use transactions for multi-table operations
- ✅ Add `db.LogMode(true)` in development to monitor queries

### 4. **Avoid Common Pitfalls**
- ❌ Don't load entire conversation history
- ❌ Don't put frequently queried fields in JSONB
- ❌ Don't create indexes you don't use (they slow down writes)
- ❌ Don't forget to use `WHERE deleted_at IS NULL` on messages
- ❌ Don't use `Preload` when you only need a count or last item

---

## 📈 Scalability Considerations

### When to Partition

**Consider partitioning `messages` table when:**
- Total messages > 100 million rows
- Table size > 100GB
- Query performance degrades even with proper indexes

**Partition strategy:**
```sql
-- Partition by conversation_id range (hash partitioning)
CREATE TABLE messages_partition_0 PARTITION OF messages
    FOR VALUES WITH (MODULUS 10, REMAINDER 0);

-- Or by time (if you have retention policies)
CREATE TABLE messages_2026_01 PARTITION OF messages
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
```

### When to Shard

**Consider database sharding when:**
- Single database > 2TB
- Cannot achieve performance targets with single DB
- Want geographic distribution

**Shard by `car_seller_id` or `region`** - keeps related data together.

---

## 🔒 Security & Authorization

### Row-Level Security (RLS)

```sql
-- Enable RLS on conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see conversations they're part of
CREATE POLICY conversation_access ON conversations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversation_participants
            WHERE conversation_id = conversations.id
              AND user_id = current_setting('app.user_id')::uuid
        )
    );
```

### Application-Level Checks

```go
// Before allowing any conversation access
func (r *ChatRepository) CheckUserAccess(userID, conversationID string) (bool, error) {
    var count int64
    
    err := r.db.Model(&ConversationParticipant{}).
        Where("conversation_id = ? AND user_id = ?", conversationID, userID).
        Count(&count).Error
    
    return count > 0, err
}
```

---

## 📝 Migration Strategy

### Safe Migration Path

```go
// Step 1: Add new columns with defaults
ALTER TABLE conversations ADD COLUMN car_seller_id UUID;
ALTER TABLE conversations ADD COLUMN car_title VARCHAR(255);

// Step 2: Backfill data
UPDATE conversations c
SET car_seller_id = cars.seller_id,
    car_title = cars.title
FROM cars
WHERE c.car_id = cars.id;

// Step 3: Add NOT NULL constraints after backfill
ALTER TABLE conversations ALTER COLUMN car_seller_id SET NOT NULL;
ALTER TABLE conversations ALTER COLUMN car_title SET NOT NULL;

// Step 4: Add indexes
CREATE INDEX idx_conversations_seller ON conversations(car_seller_id);
```

---

## 🧪 Testing Checklist

### Database Tests
- ✅ Test concurrent conversation creation (no duplicate conversations)
- ✅ Test transaction rollback on error
- ✅ Test JSONB custom type scanning with NULL values
- ✅ Test pagination boundaries (offset at end, negative offset)
- ✅ Verify indexes are being used (`EXPLAIN ANALYZE`)

### Load Tests
- ✅ 1000 concurrent message sends
- ✅ 10,000 conversation list queries/second
- ✅ Message pagination with 1M+ messages in conversation

---

## 🎓 Summary

This architecture provides:
- ✅ **Simple**: Only 3 tables, clear relationships
- ✅ **Fast**: Optimized indexes, minimal joins, efficient queries
- ✅ **Scalable**: Partitioning and sharding paths identified
- ✅ **Maintainable**: Clear separation of concerns, proper Go types
- ✅ **Correct**: JSONB usage follows best practices (hybrid approach)

**Key Takeaways:**
1. Use traditional columns for frequently queried data (car_id, timestamps)
2. Denormalize strategically (car_title, car_seller_id) to avoid joins
3. Use JSONB only for truly optional/variable data
4. Create GIN indexes on JSONB only if you query inside it
5. Always paginate messages - never load entire history
6. Use transactions for multi-table operations
7. Implement proper Scanner/Valuer for JSONB in Go
8. Monitor query performance with `EXPLAIN ANALYZE`

This design will handle millions of messages and thousands of concurrent users efficiently.
