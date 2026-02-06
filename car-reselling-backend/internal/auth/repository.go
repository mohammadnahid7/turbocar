package auth

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/yourusername/car-reselling-backend/internal/database"
	"github.com/yourusername/car-reselling-backend/internal/models"
	appErrors "github.com/yourusername/car-reselling-backend/pkg/errors"
)

// Repository handles database operations for authentication
type Repository struct {
	db *gorm.DB
}

// NewRepository creates a new authentication repository
func NewRepository() *Repository {
	return &Repository{
		db: database.DB,
	}
}

// CreateUser creates a new user in the database
func (r *Repository) CreateUser(user *models.User) error {
	if err := r.db.Create(user).Error; err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return appErrors.ErrUserAlreadyExists
		}
		return err
	}
	return nil
}

// GetUserByEmail retrieves a user by email
func (r *Repository) GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("email = ?", email).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, appErrors.ErrNotFound
		}
		return nil, err
	}
	return &user, nil
}

// GetUserByPhone retrieves a user by phone number
func (r *Repository) GetUserByPhone(phone string) (*models.User, error) {
	var user models.User
	if err := r.db.Where("phone = ?", phone).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, appErrors.ErrNotFound
		}
		return nil, err
	}
	return &user, nil
}

// GetUserByID retrieves a user by ID
func (r *Repository) GetUserByID(id string) (*models.User, error) {
	var user models.User
	userID, err := uuid.Parse(id)
	if err != nil {
		return nil, err
	}

	if err := r.db.Where("id = ?", userID).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, appErrors.ErrNotFound
		}
		return nil, err
	}
	return &user, nil
}

// UpdateUser updates a user in the database
func (r *Repository) UpdateUser(user *models.User) error {
	return r.db.Save(user).Error
}

// CreateVerificationCode creates a verification code record
func (r *Repository) CreateVerificationCode(phone, code string, expiresAt time.Time) error {
	vc := &models.VerificationCode{
		Phone:     phone,
		Code:      code,
		ExpiresAt: expiresAt,
	}
	return r.db.Create(vc).Error
}

// GetVerificationCode retrieves the latest verification code for a phone number
func (r *Repository) GetVerificationCode(phone string) (*models.VerificationCode, error) {
	var vc models.VerificationCode
	if err := r.db.Where("phone = ?", phone).
		Order("created_at DESC").
		First(&vc).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, appErrors.ErrNotFound
		}
		return nil, err
	}
	return &vc, nil
}

// IncrementOTPAttempts increments the attempt count for an OTP
func (r *Repository) IncrementOTPAttempts(phone string) error {
	return r.db.Model(&models.VerificationCode{}).
		Where("phone = ?", phone).
		Order("created_at DESC").
		Limit(1).
		Update("attempts", gorm.Expr("attempts + 1")).Error
}

// MarkOTPAsVerified marks an OTP as verified
func (r *Repository) MarkOTPAsVerified(phone string) error {
	return r.db.Model(&models.VerificationCode{}).
		Where("phone = ? AND is_verified = ?", phone, false).
		Order("created_at DESC").
		Limit(1).
		Update("is_verified", true).Error
}

// UpdateUserPassword updates only the password hash for a user
func (r *Repository) UpdateUserPassword(userID string, passwordHash string) error {
	parsedID, err := uuid.Parse(userID)
	if err != nil {
		return err
	}
	result := r.db.Model(&models.User{}).Where("id = ?", parsedID).Update("password_hash", passwordHash)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return appErrors.ErrNotFound
	}
	return nil
}
