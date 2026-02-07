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

// GetUserConversations retrieves all conversations for a user with last message
func (s *Service) GetUserConversations(userID uuid.UUID) ([]ConversationResponse, error) {
	conversations, err := s.repo.GetUserConversations(userID)
	if err != nil {
		return nil, err
	}

	responses := make([]ConversationResponse, len(conversations))
	for i, conv := range conversations {
		// Get last message
		lastMsg, _ := s.repo.GetLastMessage(conv.ID)

		// Get unread count
		unreadCount, _ := s.repo.GetUnreadCount(userID, conv.ID)

		// Build participant list
		participants := make([]ParticipantResponse, len(conv.Participants))
		for j, p := range conv.Participants {
			participants[j] = ParticipantResponse{
				UserID: p.UserID,
				// Note: FullName and AvatarURL would need to be fetched from users table
			}
		}

		responses[i] = ConversationResponse{
			ID:           conv.ID,
			CarID:        conv.CarID,
			CarTitle:     conv.CarTitle,
			Participants: participants,
			UnreadCount:  int(unreadCount),
			CreatedAt:    conv.CreatedAt.Format(time.RFC3339),
			UpdatedAt:    conv.UpdatedAt.Format(time.RFC3339),
			Metadata:     conv.Metadata,
		}

		if lastMsg != nil {
			responses[i].LastMessage = &MessageResponse{
				ID:          lastMsg.ID,
				SenderID:    lastMsg.SenderID,
				Content:     lastMsg.Content,
				MessageType: lastMsg.MessageType,
				IsRead:      lastMsg.IsRead,
				CreatedAt:   lastMsg.CreatedAt.Format(time.RFC3339),
			}
		}
	}

	return responses, nil
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

	return s.repo.SaveMessage(msg)
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
