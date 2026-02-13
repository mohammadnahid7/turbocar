# Chat & Notification System Roadmap (2026 Strategy)

> **Objective**: Build a scalable, real-time communication system for Turbocar using Go (WebSockets) and Flutter (Riverpod), ensuring <100ms latency for active chats and 99.9% delivery reliability for notifications.

## 1. Architectural Strategy

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Real-time | WebSockets (`gorilla/websocket` + `web_socket_channel`) | Standard, low-overhead, Go-native |
| Notifications | Firebase Cloud Messaging (FCM) | Reliable background/killed delivery |
| State Mgmt | Riverpod | Compile-safe, testable, stream-friendly |
| Scaling | Redis Pub/Sub | Cross-instance message broadcast |

---

## 2. Phased Execution

### Phase 1: Backend Foundation
1. **Database Schema** (`migrations/`)
   - `conversations`, `messages`, `conversation_participants`
   - `user_devices` (FCM token storage per user)
2. **Chat Module** (`internal/chat/`)
   - `models.go`, `dto.go`, `repository.go`
   - `hub.go` (client registry), `client.go` (read/write pumps)
   - `handler.go`: `GET /ws`, `GET /history`, `POST /media`
   - `service.go` (business logic)
3. **WebSocket Authentication**
   - Validate JWT on connection upgrade (token in query param)
   - Reject unauthenticated connections

### Phase 2: Flutter Real-time Client
1. **Dependencies**
   - Add: `web_socket_channel`, `dash_chat_2`
   - Remove: `socket_io_client`
2. **SocketService Rewrite** (`lib/data/services/socket_service.dart`)
   - Use `WebSocketChannel`
   - Implement exponential backoff reconnection
   - Expose `Stream<Message>` to app
3. **Offline Message Queue**
   - Queue outgoing messages locally when disconnected
   - Sync on reconnect
4. **Chat Repository & Provider**
   - `chat_repository.dart`, `chat_provider.dart`
5. **UI Screens** (`lib/presentation/pages/chat/`)
   - `ConversationListScreen`, `ChatScreen`

### Phase 3: Notifications
1. **FCM Token Management**
   - Store device token in `user_devices` on login
   - Refresh on token change
2. **Backend Trigger** (`internal/notification/service.go`)
   - On message arrival: check if recipient connected via WS
   - If NOT connected → send FCM push
3. **Flutter Handler** (`lib/core/services/notification_service.dart`)
   - Request permissions, handle foreground/background
   - Deep-link to `ChatScreen` on tap

### Phase 4: Polish & Scale
1. **Redis Pub/Sub** for multi-instance broadcasting
2. **Read Receipts** (update `last_read_message_id`, broadcast via WS)
3. **Typing Indicators** (ephemeral WS events, no DB storage)
4. **Media Upload** (`POST /media` → S3/MinIO URL)

---

## 3. Directory Structure

**Backend (`car-reselling-backend/`)**
```
internal/
├── chat/       (hub, client, handler, service, repository, models, dto)
├── notification/ (service, models)
migrations/     (SQL files)
```

**Frontend (`turbo_car/`)**
```
lib/
├── data/
│   ├── models/     (conversation_model, message_model)
│   ├── services/   (socket_service, chat_service)
│   └── repositories/ (chat_repository)
├── domain/entities/ (conversation, message)
├── presentation/
│   ├── providers/  (chat_provider)
│   └── pages/chat/ (conversation_list_screen, chat_screen)
└── core/services/  (notification_service)
```

---

## 4. Next Steps
1. Create SQL migration for all tables including `user_devices`
2. Initialize `internal/chat/` module with JWT-authenticated WebSocket
3. Update Flutter `pubspec.yaml` (add/remove dependencies)
