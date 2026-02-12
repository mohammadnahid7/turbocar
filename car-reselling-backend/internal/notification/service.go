package notification

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
)

// WebSocketSender interface for sending notifications via WebSocket
type WebSocketSender interface {
	SendNotification(userID uuid.UUID, notificationData map[string]interface{}) bool
	SendNotificationCount(userID uuid.UUID, count int64) bool
	IsUserOnline(userID uuid.UUID) bool
}

// FCMService interface for sending push notifications
type FCMService interface {
	SendToUsers(userIDs []uuid.UUID, title, body string, data map[string]string) error
}

// Service handles notification business logic
type Service struct {
	repo       *Repository
	wsSender   WebSocketSender
	fcmService FCMService
}

// NewService creates a new notification service
func NewService(repo *Repository, wsSender WebSocketSender, fcmService FCMService) *Service {
	return &Service{
		repo:       repo,
		wsSender:   wsSender,
		fcmService: fcmService,
	}
}

// CreateAndSend creates a notification and sends it via WebSocket and/or FCM
func (s *Service) CreateAndSend(ctx context.Context, userID uuid.UUID, title, message, notifType, imageURL string, data map[string]interface{}) (*Notification, error) {
	// 1. Create notification object
	notification := &Notification{
		ID:        uuid.New(),
		UserID:    userID,
		Title:     title,
		Message:   message,
		Type:      notifType,
		ImageURL:  imageURL,
		Data:      data,
		IsRead:    false,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// 2. Save to database
	if err := s.repo.Create(ctx, notification); err != nil {
		return nil, fmt.Errorf("failed to create notification: %w", err)
	}

	// 3. Try to send via WebSocket if user is online
	wsSent := false
	if s.wsSender != nil {
		notificationData := map[string]interface{}{
			"id":         notification.ID,
			"title":      notification.Title,
			"message":    notification.Message,
			"type":       notification.Type,
			"image_url":  notification.ImageURL,
			"data":       notification.Data,
			"is_read":    notification.IsRead,
			"created_at": notification.CreatedAt,
		}
		wsSent = s.wsSender.SendNotification(userID, notificationData)

		// Also send updated unread count
		if wsSent {
			unreadCount, _ := s.repo.CountUnread(ctx, userID)
			s.wsSender.SendNotificationCount(userID, unreadCount)
		}
	}

	// 4. Send via FCM if user is not online via WebSocket (or always for mobile background)
	// According to requirements: "when offline, show notification using FCM"
	if s.fcmService != nil && !wsSent {
		go s.sendFCMNotification(userID, title, message, notifType, data)
	}

	return notification, nil
}

// sendFCMNotification sends FCM notification asynchronously
func (s *Service) sendFCMNotification(userID uuid.UUID, title, body, notifType string, data map[string]interface{}) {
	// Convert data map to string map for FCM
	fcmData := make(map[string]string)
	fcmData["type"] = notifType
	fcmData["click_action"] = "FLUTTER_NOTIFICATION_CLICK"

	// Add all data fields
	for key, value := range data {
		if strVal, ok := value.(string); ok {
			fcmData[key] = strVal
		} else {
			fcmData[key] = fmt.Sprintf("%v", value)
		}
	}

	userIDs := []uuid.UUID{userID}
	if err := s.fcmService.SendToUsers(userIDs, title, body, fcmData); err != nil {
		log.Printf("Failed to send FCM notification to user %s: %v", userID, err)
	}
}

// CreateAndSendBulk creates and sends notifications to multiple users
func (s *Service) CreateAndSendBulk(ctx context.Context, userIDs []uuid.UUID, title, message, notifType, imageURL string, data map[string]interface{}) error {
	for _, userID := range userIDs {
		_, err := s.CreateAndSend(ctx, userID, title, message, notifType, imageURL, data)
		if err != nil {
			log.Printf("Failed to create notification for user %s: %v", userID, err)
			// Continue with other users
		}
	}
	return nil
}

// GetUserNotifications retrieves paginated notifications for a user
func (s *Service) GetUserNotifications(ctx context.Context, userID uuid.UUID, page, limit int) (*PaginatedNotificationsResponse, error) {
	notifications, total, err := s.repo.FindByUserID(ctx, userID, page, limit)
	if err != nil {
		return nil, err
	}

	// Get unread count
	unreadCount, err := s.repo.CountUnread(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Convert to response format
	responses := make([]NotificationResponse, len(notifications))
	for i, n := range notifications {
		responses[i] = n.ToResponse()
	}

	return &PaginatedNotificationsResponse{
		Notifications: responses,
		Total:         total,
		Page:          page,
		Limit:         limit,
		UnreadCount:   unreadCount,
	}, nil
}

// MarkAsRead marks a notification as read (verifies ownership)
func (s *Service) MarkAsRead(ctx context.Context, userID, notificationID uuid.UUID) error {
	return s.repo.MarkAsReadForUser(ctx, userID, notificationID)
}

// MarkAllAsRead marks all notifications for a user as read
func (s *Service) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	return s.repo.MarkAllAsRead(ctx, userID)
}

// GetUnreadCount returns the count of unread notifications for a user
func (s *Service) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error) {
	return s.repo.CountUnread(ctx, userID)
}

// IsUserOnline checks if a user is currently connected via WebSocket
func (s *Service) IsUserOnline(userID uuid.UUID) bool {
	if s.wsSender != nil {
		return s.wsSender.IsUserOnline(userID)
	}
	return false
}

// SetWebSocketSender sets the WebSocket sender after initialization
// This is needed because of circular dependency between notification service and chat hub
func (s *Service) SetWebSocketSender(wsSender WebSocketSender) {
	s.wsSender = wsSender
}

// SendToUsers implements the chat.NotificationSender interface
// It creates notifications in the database and sends them via FCM
func (s *Service) SendToUsers(userIDs []uuid.UUID, title, body string, data map[string]string) error {
	ctx := context.Background()

	// Convert data to map[string]interface{}
	dataMap := make(map[string]interface{})
	for k, v := range data {
		dataMap[k] = v
	}

	// Get notification type from data or default to "general"
	notifType := data["type"]
	if notifType == "" {
		notifType = "general"
	}

	// Get image URL from data if present
	imageURL := data["image_url"]

	// Create and send notifications to all users
	for _, userID := range userIDs {
		_, err := s.CreateAndSend(ctx, userID, title, body, notifType, imageURL, dataMap)
		if err != nil {
			log.Printf("Failed to create notification for user %s: %v", userID, err)
			// Continue with other users
		}
	}

	return nil
}
