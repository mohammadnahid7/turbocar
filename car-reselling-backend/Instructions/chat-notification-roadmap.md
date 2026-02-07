# Chat & Notification System Roadmap (2026 Strategy)

> **Objective**: Build a scalable, real-time communication system for Turbocar using Go (WebSockets) and Flutter (Riverpod), ensuring <100ms latency for active chats and 99.9% delivery reliability for notifications.

## 1. Architectural Strategy

### Core Technology Decisions
*   **Real-time Protocol**: **Native WebSockets** (`gorilla/websocket` on Go, `web_socket_channel` on Flutter).
    *   *Why?* Standard compliance, lower overhead than Socket.IO, and perfect integration with Go's concurrency model.
*   **Notifications**: **Firebase Cloud Messaging (FCM)**.
    *   *Why?* Industry standard for reliable push notifications on Android/iOS when the app is backgrounded/killed.
*   **State Management**: **Riverpod** (Flutter).
    *   *Why?* Compile-time safety, easy testing, and efficient state binding for real-time streams.
*   **Scalability**: **Redis Pub/Sub**.
    *   *Why?* Decouples WebSocket servers, allowing horizontal scaling without losing cross-server communication capabilities.

---

## 2. Phased Execution Logic

### Phase 1: The Foundation (Backend & Database)
**Goal**: Establish the data layer and basic WebSocket infrastructure.
1.  **Database Modeling**:
    *   PostgreSQL schema for `conversations` (rooms), `messages` (content), and `participants` (tracking read status).
    *   Indexes on `conversation_id` and `created_at` for fast history retrieval.
2.  **Go WebSocket Engine (`internal/chat`)**:
    *   **Hub**: The central orchestrator maintaining a registry of active `Client` connections.
    *   **Client**: Wrapping the WebSocket connection with read/write pumps to handle concurrency safely.
    *   **Handlers**: HTTP endpoints to upgrade connections (`GET /ws`) and serve history (`GET /history`).

### Phase 2: Real-time Client (Flutter Implementation)
**Goal**: Enable users to send/receive messages instantly when the app is open.
1.  **Service Layer**:
    *   `ChatService`: Managing the `WebSocketChannel`, handling reconnection logic, and exposing a `Stream<Message>` to the app.
    *   **Crucial Step**: Migrating away from `socket_io_client` to `web_socket_channel`.
2.  **State Management**:
    *   `ChatProvider`: A unified Riverpod provider that listens to the WebSocket stream, updates the message list optimistically, and handles error states.
3.  **UI Construction**:
    *   `ConversationList`: Real-time updates of "last message" previews.
    *   `ChatScreen`: A modern, bubble-based chat interface with "typing" indicators (optional) and message status.

### Phase 3: The "Unmissable" Layer (Notifications)
**Goal**: Re-engage users when they aren't looking at the app.
1.  **FCM Integration (Backend)**:
    *   `internal/notification/service.go`: Logic to send multicast messages via Firebase Admin SDK.
    *   Trigger logic: When a chat message arrives -> Check if recipient is connected via WS -> If NOT, send FCM push.
2.  **FCM Integration (Frontend)**:
    *   Request permissions on app start.
    *   Handle background/terminated state messages to deep-link directly to the relevant `ChatScreen`.
    *   Local Notifications for foreground messages (heads-up display) if desired.

### Phase 4: Polish & Scale
**Goal**: Production readiness and user experience enhancements.
1.  **Media Support**:
    *   `POST /media` endpoint to upload images/files (stored in S3/MinIO/Local), returning a URL to be sent as a WebSocket message.
2.  **Redis Layer**:
    *   Update the Go Hub to publish incoming messages to a Redis channel.
    *   Subscribe to the channel to broadcast messages to local clients, enabling multiple backend instances.
3.  **Read Receipts**:
    *   Update `last_read_message_id` in Postgres when a user opens a chat.
    *   Broadcast "read" events via WebSocket to update the sender's UI.

---

## 3. Directory Structure Alignment
**Strict adherence to project conventions:**

*   **Backend**: `internal/chat/` (logic), `internal/notification/` (logic), `migrations/` (SQL).
*   **Frontend**: `lib/data/` (API/Services), `lib/domain/` (Entities), `lib/presentation/` (UI/Providers).

## 4. Immediate Next Steps
1.  Initialize `internal/chat` module in Go backend.
2.  Create SQL migrations for `conversations` and `messages`.
3.  Clean up Flutter dependencies (remove `socket_io`, add `web_socket_channel`).
