package chat

import (
	"log"
	"time"

	"github.com/google/uuid"
)

// Service handles business logic for chat
type Service struct {
	repo         *Repository
	notification NotificationSender
}

// NotificationSender interface for sending push notifications
type NotificationSender interface {
	SendToUsers(userIDs []uuid.UUID, title, body string, data map[string]string) error
}

// NewService creates a new chat service
func NewService(repo *Repository, notification NotificationSender) *Service {
	return &Service{
		repo:         repo,
		notification: notification,
	}
}

// --- Conversation Operations ---

// StartConversation creates or retrieves a conversation between users about a car
func (s *Service) StartConversation(participantIDs []uuid.UUID, carID *uuid.UUID, carTitle string, context Metadata) (*Conversation, error) {
	// Check if conversation already exists between these users for this car
	existing, err := s.repo.GetConversationBetweenUsers(participantIDs, carID)
	if err == nil && existing.ID != uuid.Nil {
		return existing, nil
	}

	// Extract seller ID from participants (first participant is typically the seller)
	var carSellerID *uuid.UUID
	if len(participantIDs) > 0 {
		carSellerID = &participantIDs[0]
	}

	return s.repo.CreateConversation(participantIDs, carID, carTitle, carSellerID, context)
}

// GetUserConversations retrieves all conversations for a user with last message (optimized)
func (s *Service) GetUserConversations(userID uuid.UUID) ([]ConversationResponse, error) {
	// Use optimized query that fetches everything in one go
	items, err := s.repo.GetUserConversationsOptimized(userID, 100, 0)
	if err != nil {
		return nil, err
	}

	responses := make([]ConversationResponse, len(items))
	for i, item := range items {
		responses[i] = ConversationResponse{
			ID:          item.ID,
			CarID:       item.CarID,
			CarTitle:    item.CarTitle,
			CarImageURL: derefString(item.CarImageURL),
			CarPrice:    item.CarPrice,
			CarSellerID: item.CarSellerID,
			Participants: []ParticipantResponse{
				{
					UserID:    item.OtherUserID,
					FullName:  item.OtherUserName,
					AvatarURL: derefString(item.OtherUserAvatar),
				},
			},
			UnreadCount: item.UnreadCount,
			UpdatedAt:   derefString(item.LastMessageAt),
		}

		if item.LastMessageContent != nil {
			responses[i].LastMessage = &MessageResponse{
				SenderID:    *item.LastMessageSenderID,
				Content:     *item.LastMessageContent,
				MessageType: "text",
				CreatedAt:   derefString(item.LastMessageTime),
			}
		}
	}

	return responses, nil
}

// derefString safely dereferences a string pointer
func derefString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

// formatTimePtr safely formats a time pointer to RFC3339 string
func formatTimePtr(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.Format(time.RFC3339)
}

// --- Message Operations ---

// SaveMessage persists a WebSocket message to the database
func (s *Service) SaveMessage(wsMsg *WSMessage) error {
	msg := &Message{
		ConversationID: wsMsg.ConversationID,
		SenderID:       wsMsg.SenderID,
		Content:        wsMsg.Content,
		MessageType:    wsMsg.MessageType,
		CreatedAt:      wsMsg.Timestamp,
	}

	if wsMsg.MediaURL != "" {
		msg.MediaURL = &wsMsg.MediaURL
	}

	// Save message to database
	if err := s.repo.SaveMessage(msg); err != nil {
		return err
	}

	// Increment unread count for other participants
	if err := s.repo.IncrementUnreadCount(wsMsg.ConversationID, wsMsg.SenderID); err != nil {
		log.Printf("Failed to increment unread count: %v", err)
		// Don't fail the message send for this
	}

	return nil
}

// GetChatHistory retrieves paginated messages
func (s *Service) GetChatHistory(conversationID uuid.UUID, page, pageSize int) (*ChatHistoryResponse, error) {
	messages, total, err := s.repo.GetMessages(conversationID, page, pageSize)
	if err != nil {
		return nil, err
	}

	responses := make([]MessageResponse, len(messages))
	for i, msg := range messages {
		mediaURL := ""
		if msg.MediaURL != nil {
			mediaURL = *msg.MediaURL
		}

		responses[i] = MessageResponse{
			ID:             msg.ID,
			ConversationID: msg.ConversationID,
			SenderID:       msg.SenderID,
			Content:        msg.Content,
			MessageType:    msg.MessageType,
			MediaURL:       mediaURL,
			IsRead:         msg.IsRead,
			Status:         msg.Status,
			DeliveredAt:    formatTimePtr(msg.DeliveredAt),
			SeenAt:         formatTimePtr(msg.SeenAt),
			CreatedAt:      msg.CreatedAt.Format(time.RFC3339),
		}
	}

	return &ChatHistoryResponse{
		Messages:   responses,
		TotalCount: total,
		Page:       page,
		PageSize:   pageSize,
	}, nil
}

// MarkAsRead marks messages as read for a user
func (s *Service) MarkAsRead(userID, conversationID uuid.UUID, messageIDStr string) error {
	messageID, err := uuid.Parse(messageIDStr)
	if err != nil {
		return err
	}
	return s.repo.MarkMessagesAsRead(userID, conversationID, messageID)
}

// GetParticipantIDs returns participant user IDs (used by Hub)
func (s *Service) GetParticipantIDs(conversationID uuid.UUID) ([]uuid.UUID, error) {
	return s.repo.GetParticipantIDs(conversationID)
}

// --- Notification Operations ---

// SendPushNotifications sends FCM notifications to offline users
func (s *Service) SendPushNotifications(userIDs []uuid.UUID, msg *WSMessage) {
	if s.notification == nil {
		log.Println("Notification service not configured")
		return
	}

	title := "New Message"
	body := msg.Content
	if len(body) > 100 {
		body = body[:97] + "..."
	}

	data := map[string]string{
		"conversation_id": msg.ConversationID.String(),
		"sender_id":       msg.SenderID.String(),
		"type":            "chat_message",
	}

	if err := s.notification.SendToUsers(userIDs, title, body, data); err != nil {
		log.Printf("Failed to send push notifications: %v", err)
	}
}

// --- Device Operations ---

// RegisterDevice stores FCM token for a user
func (s *Service) RegisterDevice(userID uuid.UUID, fcmToken, deviceType string) error {
	device := &UserDevice{
		UserID:     userID,
		FCMToken:   fcmToken,
		DeviceType: deviceType,
	}
	return s.repo.SaveUserDevice(device)
}

// UnregisterDevice removes FCM token for a user
func (s *Service) UnregisterDevice(userID uuid.UUID, fcmToken string) error {
	return s.repo.DeleteUserDevice(userID, fcmToken)
}

// --- Message Status Operations ---

// MarkMessageDelivered updates a message status to delivered
func (s *Service) MarkMessageDelivered(messageID uuid.UUID) error {
	now := time.Now()
	return s.repo.UpdateMessageStatus(messageID, "delivered", &now)
}

// MarkConversationSeen marks all messages in a conversation as seen for a user and resets unread count
func (s *Service) MarkConversationSeen(conversationID, userID uuid.UUID) (int64, error) {
	// Mark all messages as seen
	affected, err := s.repo.BulkUpdateMessagesSeen(conversationID, userID)
	if err != nil {
		return 0, err
	}

	// Reset unread count for this user
	if err := s.repo.ResetUnreadCount(conversationID, userID); err != nil {
		log.Printf("Failed to reset unread count: %v", err)
	}

	return affected, nil
}

// GetTotalUnreadCount returns the sum of all unread counts for a user
func (s *Service) GetTotalUnreadCount(userID uuid.UUID) (int64, error) {
	return s.repo.GetTotalUnreadCount(userID)
}

// ResetUnreadCount resets the unread count for a specific conversation
func (s *Service) ResetUnreadCount(conversationID, userID uuid.UUID) error {
	return s.repo.ResetUnreadCount(conversationID, userID)
}
