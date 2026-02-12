package notification

import (
	"context"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository handles database operations for notifications
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a new notification repository
func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create saves a new notification to the database
func (r *Repository) Create(ctx context.Context, notification *Notification) error {
	return r.db.WithContext(ctx).Create(notification).Error
}

// FindByUserID retrieves paginated notifications for a user
func (r *Repository) FindByUserID(ctx context.Context, userID uuid.UUID, page, limit int) ([]Notification, int64, error) {
	var notifications []Notification
	var total int64

	offset := (page - 1) * limit

	// Count total
	err := r.db.WithContext(ctx).Model(&Notification{}).Where("user_id = ?", userID).Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	// Get paginated results
	err = r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&notifications).Error

	return notifications, total, err
}

// FindByID retrieves a single notification by ID
func (r *Repository) FindByID(ctx context.Context, notificationID uuid.UUID) (*Notification, error) {
	var notification Notification
	err := r.db.WithContext(ctx).First(&notification, "id = ?", notificationID).Error
	if err != nil {
		return nil, err
	}
	return &notification, nil
}

// MarkAsRead marks a specific notification as read
func (r *Repository) MarkAsRead(ctx context.Context, notificationID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("id = ?", notificationID).
		Update("is_read", true).Error
}

// MarkAsReadForUser marks a notification as read only if it belongs to the specified user
func (r *Repository) MarkAsReadForUser(ctx context.Context, userID, notificationID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("id = ? AND user_id = ?", notificationID, userID).
		Update("is_read", true).Error
}

// MarkAllAsRead marks all notifications for a user as read
func (r *Repository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Update("is_read", true).Error
}

// CountUnread returns the count of unread notifications for a user
func (r *Repository) CountUnread(ctx context.Context, userID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Count(&count).Error
	return count, err
}

// DeleteOldNotifications removes notifications older than the specified duration
func (r *Repository) DeleteOldNotifications(ctx context.Context, days int) error {
	return r.db.WithContext(ctx).
		Where("created_at < NOW() - INTERVAL '? days'", days).
		Delete(&Notification{}).Error
}
