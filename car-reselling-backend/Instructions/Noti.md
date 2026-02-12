# Price Change Notification System Implementation Plan

## Goal Description
Implement a complete notification system for "Price Change" events. When a car seller updates the price of a car, all users who have favorited that car should receive a notification. The system must support:
- Persistence: Save notifications to the database.
- Real-time: Deliver notifications via WebSocket when the user is in-app.
- Push: Deliver notifications via FCM when the user is offline/background.
- History: Allow users to view past notifications and mark them as read.

> [!IMPORTANT]
> **Schema Change**: A new `notifications` table will be created.
> **WebSocket Strategy**: We will reuse/extend the existing Chat WebSocket connection to handle generic "events" (like notifications) to avoid multiple socket connections per client.

## Proposed Changes

### Database
#### [NEW] `migrations/010_create_notifications_table.sql`
- Create `notifications` table:
    - `id` (UUID, PK)
    - `user_id` (UUID, FK -> users)
    - `title` (VARCHAR)
    - `message` (TEXT)
    - `type` (VARCHAR) - e.g., "price_change"
    - `image_url` (VARCHAR) - optional, for car image
    - [data](file:///c:/Users/Nahid/Desktop/Programming/turbocar/turbo_car/.metadata) (JSONB) - flex fields (car_id, old_price, new_price)
    - `is_read` (BOOLEAN, default false)
    - `created_at` (TIMESTAMPTZ)
- Create indexes on `user_id` and `created_at`.

### Backend (`car-reselling-backend`)

#### `internal/notification` implementation
- **[NEW] `model.go`**: Define `Notification` struct matching the DB table.
- **[NEW] `repository.go`**:
    - `Create(ctx, notification *Notification) error`
    - `FindByUserID(ctx, userID, page, limit) ([]Notification, total, error)`
    - `MarkAsRead(ctx, notificationID) error`
    - `MarkAllAsRead(ctx, userID) error`
    - `CountUnread(ctx, userID) (int, error)`
- **[MODIFY] `service.go`**:
    - Inject `NotificationRepository` and `ChatHub` (or a generic `EventHub` interface).
    - Add `CreateAndSend(ctx, userID, title, body, type, data, image_url)`:
        1. Create `Notification` object.
        2. Save to DB via Repository.
        3. Try sending via WebSocket (if user connected).
        4. Send via FCM (always or fallback? Requirement says "offline show notification using FCM". Usually we send FCM always for mobile OS logic, but if socket is active we might silence it? Simplest is send both, app handles duplicate, or send FCM only if socket send fails/user not connected. Requirement: "use websocket... when offline, show notification using FCM". We can try WS first, if user not in hub, send FCM. Or send both and app de-dupes).
        - *Refinement*: Users want to see the notification history even if they saw the pop-up. So DB save is must.

#### `internal/chat` (WebSocket Logic)
- **[MODIFY] `models.go`**:
    - Add `Data map[string]interface{} \`json:"data,omitempty"\`` to `WSMessage` struct to support flexible payloads.
- **[MODIFY] `hub.go` / `client.go`**:
    - Add `SendNotification(userID, notification)` method to `Hub`.
    - Implement `notification:unread` event type to push unread notification counts separately from chat unread counts.

#### `internal/listing` (Trigger)
- **[MODIFY] `service.go`**:
    - Update `sendPriceChangeNotifications` to call `notificationService.CreateAndSend` instead of direct FCM `SendToUsers`.

#### `cmd/api`
- **[MODIFY] `main.go`**:
    - Wire up `NotificationRepository`.
    - Inject `ChatHub` into `NotificationService`.

### Frontend Flow (Analysis)
1.  **Trigger**: User B (Owner) changes price of Car X.
2.  **Backend Trigger**: `ListingService` sees price diff -> Finds Users who favorited Car X (User A).
3.  **Notification Creation**: Backend creating `Notification` record for User A.
4.  **Delivery**:
    -   **Socket**: properties `type: "notification"`, `payload: { ... }`. App shows in-app snackbar/dot.
    -   **FCM**: App receives push. System tray.
5.  **Consumption**:
    -   User A opens app. WebSocket connects.
    -   Home Screen: WebSocket event `notification_count` updates badge.
    -   User goes to Notification Page: Calls `GET /api/notifications`.
    -   List shows "Price Drop! BMW M4: $50k -> $45k".
    -   Click -> Navigate to Car Details.
    -   Click marks as read (API call).

## Verification Plan

### Automated Tests
- **Unit Tests**:
    - `notification/service_test.go`: Mock Repo and Hub. Verify `CreateAndSend` calls repo.Create and hub.Send/FCM.send.
    - `listing/service_test.go`: Verify `UpdateListing` triggers notification service when price changes.

### Manual Verification
1.  **Database**: Run migration, check table exists.
2.  **WebSocket**:
    -   Connect using Postman/scat to `ws://localhost:8080/api/chat/ws`.
    -   Trigger price change via API.
    -   Verify JSON message received on socket.
3.  **FCM**:
    -   (Hard to test without real app/certs, but can check logs "FCM: Sent...").
4.  **API**:
    -   Call `GET /api/notifications` -> See the new notification.
    -   Call `PUT /api/notifications/:id/read` -> Verify `is_read` becomes true in DB.
