package chat

import (
	"github.com/google/uuid"
)

// --- Request DTOs ---

// SendMessageRequest is the payload for sending a message
type SendMessageRequest struct {
	ConversationID uuid.UUID `json:"conversation_id" binding:"required"`
	Content        string    `json:"content"`
	MessageType    string    `json:"message_type"` // text, image, file
	MediaURL       string    `json:"media_url,omitempty"`
}

// StartConversationRequest creates a new conversation
type StartConversationRequest struct {
	ParticipantIDs []uuid.UUID `json:"participant_ids" binding:"required,min=1"`
	CarID          *uuid.UUID  `json:"car_id,omitempty"`
	CarTitle       string      `json:"car_title,omitempty"`
	Context        Metadata    `json:"context,omitempty"`
}

// MarkAsReadRequest marks messages as read
type MarkAsReadRequest struct {
	ConversationID uuid.UUID `json:"conversation_id" binding:"required"`
	MessageID      uuid.UUID `json:"message_id" binding:"required"`
}

// --- Response DTOs ---

// ConversationResponse is the API response for a conversation
type ConversationResponse struct {
	ID           uuid.UUID             `json:"id"`
	CarID        *uuid.UUID            `json:"car_id,omitempty"`
	CarTitle     string                `json:"car_title,omitempty"`
	CarImageURL  string                `json:"car_image_url,omitempty"`
	CarPrice     *float64              `json:"car_price,omitempty"`
	CarSellerID  *uuid.UUID            `json:"car_seller_id,omitempty"`
	Participants []ParticipantResponse `json:"participants"`
	LastMessage  *MessageResponse      `json:"last_message,omitempty"`
	UnreadCount  int                   `json:"unread_count"`
	CreatedAt    string                `json:"created_at"`
	UpdatedAt    string                `json:"updated_at"`
	Metadata     Metadata              `json:"metadata,omitempty"`
}

// ParticipantResponse represents a user in a conversation
type ParticipantResponse struct {
	UserID    uuid.UUID `json:"user_id"`
	FullName  string    `json:"full_name"`
	AvatarURL string    `json:"avatar_url,omitempty"`
}

// MessageResponse is the API response for a message
type MessageResponse struct {
	ID             uuid.UUID `json:"id"`
	ConversationID uuid.UUID `json:"conversation_id"`
	SenderID       uuid.UUID `json:"sender_id"`
	SenderName     string    `json:"sender_name,omitempty"`
	Content        string    `json:"content"`
	MessageType    string    `json:"message_type"`
	MediaURL       string    `json:"media_url,omitempty"`
	IsRead         bool      `json:"is_read"`
	Status         string    `json:"status"`
	DeliveredAt    string    `json:"delivered_at,omitempty"`
	SeenAt         string    `json:"seen_at,omitempty"`
	CreatedAt      string    `json:"created_at"`
}

// ChatHistoryResponse is paginated message history
type ChatHistoryResponse struct {
	Messages   []MessageResponse `json:"messages"`
	TotalCount int64             `json:"total_count"`
	Page       int               `json:"page"`
	PageSize   int               `json:"page_size"`
}
