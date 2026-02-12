package chat

import (
	"time"

	"github.com/google/uuid"
)

// Conversation represents a chat room between users about a specific car
type Conversation struct {
	ID uuid.UUID `json:"id" gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`

	// Car context (denormalized for performance)
	CarID       *uuid.UUID `json:"car_id,omitempty" gorm:"type:uuid;index"`
	CarTitle    string     `json:"car_title,omitempty" gorm:"type:varchar(255)"`
	CarSellerID *uuid.UUID `json:"car_seller_id,omitempty" gorm:"type:uuid;index"`

	// Timestamps
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
	LastMessageAt *time.Time `json:"last_message_at,omitempty" gorm:"index"`

	// Flexible metadata with proper JSONB handling
	Metadata Metadata `json:"metadata,omitempty" gorm:"type:jsonb;default:'{}'"`

	// Relations
	Participants []ConversationParticipant `json:"participants,omitempty" gorm:"foreignKey:ConversationID"`
	Messages     []Message                 `json:"messages,omitempty" gorm:"foreignKey:ConversationID"`
}

// ConversationParticipant links users to conversations
type ConversationParticipant struct {
	ConversationID    uuid.UUID  `json:"conversation_id" gorm:"type:uuid;primaryKey"`
	UserID            uuid.UUID  `json:"user_id" gorm:"type:uuid;primaryKey"`
	LastReadMessageID *uuid.UUID `json:"last_read_message_id" gorm:"type:uuid"`
	UnreadCount       int        `json:"unread_count" gorm:"default:0"`
	JoinedAt          time.Time  `json:"joined_at"`
}

// Message represents a single chat message
type Message struct {
	ID             uuid.UUID  `json:"id" gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	ConversationID uuid.UUID  `json:"conversation_id" gorm:"type:uuid;index"`
	SenderID       uuid.UUID  `json:"sender_id" gorm:"type:uuid;index"`
	Content        string     `json:"content"`
	MessageType    string     `json:"message_type" gorm:"default:text"` // text, image, file
	MediaURL       *string    `json:"media_url,omitempty"`
	IsRead         bool       `json:"is_read" gorm:"default:false"`
	Status         string     `json:"status" gorm:"default:sent"` // sent, delivered, seen
	DeliveredAt    *time.Time `json:"delivered_at,omitempty"`
	SeenAt         *time.Time `json:"seen_at,omitempty"`
	CreatedAt      time.Time  `json:"created_at" gorm:"index"`
}

// UserDevice stores FCM tokens for push notifications
type UserDevice struct {
	ID         uuid.UUID `json:"id" gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	UserID     uuid.UUID `json:"user_id" gorm:"type:uuid;index"`
	FCMToken   string    `json:"fcm_token" gorm:"size:512"`
	DeviceType string    `json:"device_type" gorm:"default:android"` // android, ios, web
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

// WSMessage is the structure for WebSocket messages
type WSMessage struct {
	Type           string                 `json:"type"` // message, typing, read_receipt, notification
	ConversationID uuid.UUID              `json:"conversation_id,omitempty"`
	SenderID       uuid.UUID              `json:"sender_id,omitempty"`
	Content        string                 `json:"content,omitempty"`
	MessageType    string                 `json:"message_type,omitempty"`
	MediaURL       string                 `json:"media_url,omitempty"`
	Data           map[string]interface{} `json:"data,omitempty"` // Flexible data for notifications and other events
	Timestamp      time.Time              `json:"timestamp"`
}

// Table name overrides for GORM
func (Conversation) TableName() string            { return "conversations" }
func (ConversationParticipant) TableName() string { return "conversation_participants" }
func (Message) TableName() string                 { return "messages" }
func (UserDevice) TableName() string              { return "user_devices" }
