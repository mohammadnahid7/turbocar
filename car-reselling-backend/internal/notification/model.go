package notification

import (
	"time"

	"github.com/google/uuid"
)

// Notification represents a user notification in the system
type Notification struct {
	ID        uuid.UUID              `json:"id" gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	UserID    uuid.UUID              `json:"user_id" gorm:"type:uuid;index;not null"`
	Title     string                 `json:"title" gorm:"type:varchar(255);not null"`
	Message   string                 `json:"message" gorm:"type:text;not null"`
	Type      string                 `json:"type" gorm:"type:varchar(50);default:'general'"` // price_change, general, etc.
	ImageURL  string                 `json:"image_url,omitempty" gorm:"type:varchar(512)"`
	Data      map[string]interface{} `json:"data,omitempty" gorm:"type:jsonb;serializer:json"`
	IsRead    bool                   `json:"is_read" gorm:"default:false"`
	CreatedAt time.Time              `json:"created_at"`
	UpdatedAt time.Time              `json:"updated_at"`
}

// TableName specifies the table name for GORM
func (Notification) TableName() string {
	return "notifications"
}

// NotificationResponse is the API response format
type NotificationResponse struct {
	ID        uuid.UUID              `json:"id"`
	Title     string                 `json:"title"`
	Message   string                 `json:"message"`
	Type      string                 `json:"type"`
	ImageURL  string                 `json:"image_url,omitempty"`
	Data      map[string]interface{} `json:"data,omitempty"`
	IsRead    bool                   `json:"is_read"`
	CreatedAt time.Time              `json:"created_at"`
}

// ToResponse converts a Notification to NotificationResponse
func (n *Notification) ToResponse() NotificationResponse {
	return NotificationResponse{
		ID:        n.ID,
		Title:     n.Title,
		Message:   n.Message,
		Type:      n.Type,
		ImageURL:  n.ImageURL,
		Data:      n.Data,
		IsRead:    n.IsRead,
		CreatedAt: n.CreatedAt,
	}
}

// PaginatedNotificationsResponse for listing notifications
type PaginatedNotificationsResponse struct {
	Notifications []NotificationResponse `json:"notifications"`
	Total         int64                  `json:"total"`
	Page          int                    `json:"page"`
	Limit         int                    `json:"limit"`
	UnreadCount   int64                  `json:"unread_count"`
}

// UnreadCountResponse for unread count endpoint
type UnreadCountResponse struct {
	Count int64 `json:"count"`
}
