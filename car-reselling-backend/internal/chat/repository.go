package chat

import (
	"errors"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository handles database operations for chat
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a new chat repository
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// --- Conversation Operations ---

// CreateConversation creates a new conversation with participants and car context
func (r *Repository) CreateConversation(participantIDs []uuid.UUID, carID *uuid.UUID, carTitle string, carSellerID *uuid.UUID, metadata Metadata) (*Conversation, error) {
	conv := &Conversation{
		CarID:       carID,
		CarTitle:    carTitle,
		CarSellerID: carSellerID,
		Metadata:    metadata,
	}

	err := r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(conv).Error; err != nil {
			return err
		}

		for _, userID := range participantIDs {
			participant := ConversationParticipant{
				ConversationID: conv.ID,
				UserID:         userID,
			}
			if err := tx.Create(&participant).Error; err != nil {
				return err
			}
		}
		return nil
	})

	if err != nil {
		return nil, err
	}

	// Reload with participants
	err = r.db.Preload("Participants").First(conv, "id = ?", conv.ID).Error
	return conv, err
}

// GetConversationByID retrieves a conversation by ID
func (r *Repository) GetConversationByID(id uuid.UUID) (*Conversation, error) {
	var conv Conversation
	err := r.db.Preload("Participants").First(&conv, "id = ?", id).Error
	return &conv, err
}

// GetUserConversations retrieves all conversations for a user (legacy - use GetUserConversationsOptimized)
func (r *Repository) GetUserConversations(userID uuid.UUID) ([]Conversation, error) {
	var conversations []Conversation

	err := r.db.
		Joins("JOIN conversation_participants cp ON cp.conversation_id = conversations.id").
		Where("cp.user_id = ?", userID).
		Preload("Participants").
		Order("COALESCE(last_message_at, updated_at) DESC").
		Find(&conversations).Error

	return conversations, err
}

// ConversationListItem is the result struct for the optimized conversation list query
type ConversationListItem struct {
	ID                  uuid.UUID  `json:"id"`
	CarID               *uuid.UUID `json:"car_id,omitempty"`
	CarTitle            string     `json:"car_title,omitempty"`
	LastMessageAt       *string    `json:"last_message_at,omitempty"`
	UnreadCount         int        `json:"unread_count"`
	OtherUserID         uuid.UUID  `json:"other_user_id"`
	OtherUserName       string     `json:"other_user_name"`
	OtherUserAvatar     *string    `json:"other_user_avatar,omitempty"`
	LastMessageContent  *string    `json:"last_message_content,omitempty"`
	LastMessageSenderID *uuid.UUID `json:"last_message_sender_id,omitempty"`
	LastMessageTime     *string    `json:"last_message_time,omitempty"`
}

// GetUserConversationsOptimized retrieves all conversations with last message & unread count in ONE query
func (r *Repository) GetUserConversationsOptimized(userID uuid.UUID, limit, offset int) ([]ConversationListItem, error) {
	var results []ConversationListItem

	// Single optimized query using LATERAL JOIN for last message
	err := r.db.Raw(`
		SELECT 
			c.id,
			c.car_id,
			c.car_title,
			TO_CHAR(c.last_message_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as last_message_at,
			-- Unread count: messages not sent by this user and not read
			(SELECT COUNT(*) FROM messages m 
			 WHERE m.conversation_id = c.id 
			   AND m.sender_id != $1 
			   AND m.is_read = false) as unread_count,
			-- Other participant info
			other_cp.user_id as other_user_id,
			u.full_name as other_user_name,
			u.profile_photo_url as other_user_avatar,
			-- Last message info via LATERAL
			lm.content as last_message_content,
			lm.sender_id as last_message_sender_id,
			TO_CHAR(lm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as last_message_time
		FROM conversations c
		INNER JOIN conversation_participants cp 
			ON cp.conversation_id = c.id AND cp.user_id = $1
		INNER JOIN conversation_participants other_cp 
			ON other_cp.conversation_id = c.id AND other_cp.user_id != $1
		LEFT JOIN users u ON u.id = other_cp.user_id
		LEFT JOIN LATERAL (
			SELECT content, sender_id, created_at
			FROM messages
			WHERE conversation_id = c.id
			ORDER BY created_at DESC
			LIMIT 1
		) lm ON true
		ORDER BY COALESCE(c.last_message_at, c.updated_at) DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset).Scan(&results).Error

	return results, err
}

// GetConversationBetweenUsers finds existing conversation between users for a specific car
func (r *Repository) GetConversationBetweenUsers(userIDs []uuid.UUID, carID *uuid.UUID) (*Conversation, error) {
	var conv Conversation

	// Find conversation where ALL specified users are participants
	subquery := r.db.Table("conversation_participants").
		Select("conversation_id").
		Where("user_id IN ?", userIDs).
		Group("conversation_id").
		Having("COUNT(DISTINCT user_id) = ?", len(userIDs))

	query := r.db.Where("id IN (?)", subquery)

	// If carID is provided, also filter by car_id
	if carID != nil {
		query = query.Where("car_id = ?", *carID)
	}

	err := query.Preload("Participants").First(&conv).Error

	return &conv, err
}

// GetParticipantIDs returns all participant user IDs for a conversation
func (r *Repository) GetParticipantIDs(conversationID uuid.UUID) ([]uuid.UUID, error) {
	var participants []ConversationParticipant
	err := r.db.Where("conversation_id = ?", conversationID).Find(&participants).Error
	if err != nil {
		return nil, err
	}

	ids := make([]uuid.UUID, len(participants))
	for i, p := range participants {
		ids[i] = p.UserID
	}
	return ids, nil
}

// --- Message Operations ---

// SaveMessage persists a message to the database and updates conversation timestamps
func (r *Repository) SaveMessage(msg *Message) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(msg).Error; err != nil {
			return err
		}

		// Update conversation's last_message_at and updated_at atomically
		return tx.Model(&Conversation{}).
			Where("id = ?", msg.ConversationID).
			Updates(map[string]interface{}{
				"last_message_at": msg.CreatedAt,
				"updated_at":      msg.CreatedAt,
			}).Error
	})
}

// GetMessages retrieves paginated messages for a conversation
func (r *Repository) GetMessages(conversationID uuid.UUID, page, pageSize int) ([]Message, int64, error) {
	var messages []Message
	var total int64

	r.db.Model(&Message{}).Where("conversation_id = ?", conversationID).Count(&total)

	offset := (page - 1) * pageSize
	err := r.db.
		Where("conversation_id = ?", conversationID).
		Order("created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&messages).Error

	return messages, total, err
}

// GetLastMessage retrieves the most recent message in a conversation
func (r *Repository) GetLastMessage(conversationID uuid.UUID) (*Message, error) {
	var msg Message
	err := r.db.
		Where("conversation_id = ?", conversationID).
		Order("created_at DESC").
		First(&msg).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &msg, err
}

// MarkMessagesAsRead marks all messages up to a certain message as read
func (r *Repository) MarkMessagesAsRead(userID, conversationID, messageID uuid.UUID) error {
	// Update is_read for messages not sent by this user
	err := r.db.Model(&Message{}).
		Where("conversation_id = ? AND sender_id != ? AND created_at <= (SELECT created_at FROM messages WHERE id = ?)",
			conversationID, userID, messageID).
		Update("is_read", true).Error
	if err != nil {
		return err
	}

	// Update last_read_message_id for the participant
	return r.db.Model(&ConversationParticipant{}).
		Where("conversation_id = ? AND user_id = ?", conversationID, userID).
		Update("last_read_message_id", messageID).Error
}

// GetUnreadCount returns the count of unread messages for a user in a conversation
func (r *Repository) GetUnreadCount(userID, conversationID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&Message{}).
		Where("conversation_id = ? AND sender_id != ? AND is_read = false", conversationID, userID).
		Count(&count).Error
	return count, err
}

// --- Device Operations ---

// SaveUserDevice stores or updates FCM token
func (r *Repository) SaveUserDevice(device *UserDevice) error {
	return r.db.Save(device).Error
}

// GetUserDevices retrieves all devices for a user
func (r *Repository) GetUserDevices(userID uuid.UUID) ([]UserDevice, error) {
	var devices []UserDevice
	err := r.db.Where("user_id = ?", userID).Find(&devices).Error
	return devices, err
}

// DeleteUserDevice removes a device token
func (r *Repository) DeleteUserDevice(userID uuid.UUID, fcmToken string) error {
	return r.db.Where("user_id = ? AND fcm_token = ?", userID, fcmToken).Delete(&UserDevice{}).Error
}
