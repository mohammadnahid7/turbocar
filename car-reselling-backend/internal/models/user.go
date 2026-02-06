package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a user in the system
type User struct {
	ID              uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email           string     `gorm:"uniqueIndex;not null" json:"email"`
	Phone           string     `gorm:"uniqueIndex;not null" json:"phone"`
	PasswordHash    string     `gorm:"not null" json:"-"`
	FullName        string     `gorm:"not null" json:"full_name"`
	Gender          *string    `json:"gender"`
	DOB             *time.Time `json:"dob"`
	ProfilePhotoURL *string    `json:"profile_photo_url"`
	IsVerified      bool       `gorm:"default:false" json:"is_verified"`
	IsDealer        bool       `gorm:"default:false" json:"is_dealer"`
	IsActive        bool       `gorm:"default:true" json:"is_active"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
	LastLoginAt     *time.Time `json:"last_login_at"`
}

// BeforeCreate hook to generate UUID if not set
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}

// VerificationCode represents an OTP verification code
type VerificationCode struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Phone      string    `gorm:"index;not null" json:"phone"`
	Code       string    `gorm:"not null" json:"-"`
	Attempts   int       `gorm:"default:0" json:"attempts"`
	IsVerified bool      `gorm:"default:false" json:"is_verified"`
	CreatedAt  time.Time `json:"created_at"`
	ExpiresAt  time.Time `gorm:"index" json:"expires_at"`
}

// BeforeCreate hook to generate UUID if not set
func (v *VerificationCode) BeforeCreate(tx *gorm.DB) error {
	if v.ID == uuid.Nil {
		v.ID = uuid.New()
	}
	return nil
}
