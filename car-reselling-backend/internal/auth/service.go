package auth

import (
	"context"
	"fmt"
	"time"

	"github.com/yourusername/car-reselling-backend/internal/config"
	"github.com/yourusername/car-reselling-backend/internal/database"
	"github.com/yourusername/car-reselling-backend/internal/models"
	appErrors "github.com/yourusername/car-reselling-backend/pkg/errors"
	"github.com/yourusername/car-reselling-backend/pkg/utils"
)

// Service handles authentication business logic
type Service struct {
	repo   *Repository
	config *config.Config
}

// NewService creates a new authentication service
func NewService(repo *Repository, cfg *config.Config) *Service {
	return &Service{
		repo:   repo,
		config: cfg,
	}
}

// Register handles user registration
func (s *Service) Register(ctx context.Context, req *RegisterRequest) error {
	// Validate input with specific error messages
	if !utils.ValidateEmail(req.Email) {
		return appErrors.ErrInvalidEmail
	}
	if !utils.ValidatePhone(req.Phone) {
		return appErrors.ErrInvalidPhone
	}
	if err := utils.ValidatePassword(req.Password); err != nil {
		return err
	}

	// Check if user already exists
	_, err := s.repo.GetUserByEmail(req.Email)
	if err == nil {
		return appErrors.ErrUserAlreadyExists
	}
	_, err = s.repo.GetUserByPhone(req.Phone)
	if err == nil {
		return appErrors.ErrUserAlreadyExists
	}

	// Hash password
	passwordHash, err := utils.HashPassword(req.Password)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &models.User{
		Email:        utils.SanitizeString(req.Email),
		Phone:        utils.SanitizeString(req.Phone),
		PasswordHash: passwordHash,
		FullName:     utils.SanitizeString(req.FullName),
		IsVerified:   true, // Auto-verify users (OTP disabled)
		IsActive:     true, // Auto-activate users
	}

	if err := s.repo.CreateUser(user); err != nil {
		return err
	}

	// OTP disabled - users are immediately verified
	return nil
}

// Login handles user login
func (s *Service) Login(ctx context.Context, req *LoginRequest) (*AuthResponse, error) {
	// Get user by email or phone
	var user *models.User
	var err error

	if utils.ValidateEmail(req.EmailOrPhone) {
		user, err = s.repo.GetUserByEmail(req.EmailOrPhone)
	} else if utils.ValidatePhone(req.EmailOrPhone) {
		user, err = s.repo.GetUserByPhone(req.EmailOrPhone)
	} else {
		return nil, appErrors.ErrInvalidCredentials
	}

	if err != nil {
		return nil, appErrors.ErrInvalidCredentials
	}

	// Check password
	if !utils.CheckPassword(req.Password, user.PasswordHash) {
		return nil, appErrors.ErrInvalidCredentials
	}

	// Check if user is verified
	if !user.IsVerified {
		return nil, appErrors.ErrUserNotVerified
	}

	// Check if user is active
	if !user.IsActive {
		return nil, appErrors.ErrForbidden
	}

	// Generate tokens
	accessToken, err := utils.GenerateAccessToken(user.ID.String(), user.Email, s.config.JWTSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := utils.GenerateRefreshToken(user.ID.String(), s.config.JWTRefreshSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Store refresh token in Redis (30 days expiry)
	sessionKey := fmt.Sprintf("session:%s", user.ID.String())
	if err := database.Set(ctx, sessionKey, refreshToken, 5*365*24*time.Hour); err != nil {
		return nil, fmt.Errorf("failed to store session: %w", err)
	}

	// Update last login
	now := time.Now()
	user.LastLoginAt = &now
	if err := s.repo.UpdateUser(user); err != nil {
		// Log error but don't fail login
		fmt.Printf("Warning: failed to update last login: %v\n", err)
	}

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         s.userToDTO(user),
	}, nil
}

// SendOTP sends an OTP to the phone number
func (s *Service) SendOTP(ctx context.Context, phone string) error {
	// Validate phone format
	if !utils.ValidatePhone(phone) {
		return appErrors.ErrInvalidPhone
	}

	// Check rate limiting (max 3 attempts per hour)
	rateLimitKey := fmt.Sprintf("otp_rate_limit:%s", phone)
	attempts, err := database.Get(ctx, rateLimitKey)
	if err == nil {
		var count int
		fmt.Sscanf(attempts, "%d", &count)
		if count >= 3 {
			return appErrors.ErrTooManyAttempts
		}
	}

	// Generate OTP
	otpCode := utils.GenerateOTP()

	// Save to Redis with 10 minute TTL
	otpKey := fmt.Sprintf("otp:%s", phone)
	if err := database.Set(ctx, otpKey, otpCode, 10*time.Minute); err != nil {
		return fmt.Errorf("failed to store OTP: %w", err)
	}

	// Increment rate limit counter
	if _, err := database.Increment(ctx, rateLimitKey); err == nil {
		database.Set(ctx, rateLimitKey, "1", time.Hour)
	}

	// Send via Twilio
	if s.config.TwilioAccountSID != "" && s.config.TwilioAuthToken != "" {
		if err := utils.SendOTP(
			phone,
			otpCode,
			s.config.TwilioAccountSID,
			s.config.TwilioAuthToken,
			s.config.TwilioPhoneNumber,
		); err != nil {
			// Log error but don't fail (for development, OTP might be in logs)
			fmt.Printf("Warning: failed to send OTP via Twilio: %v\n", err)
			fmt.Printf("OTP for %s: %s\n", phone, otpCode) // For development
		}
	} else {
		// Development mode: print OTP to console
		fmt.Printf("OTP for %s: %s\n", phone, otpCode)
	}

	return nil
}

// VerifyOTP verifies an OTP code
func (s *Service) VerifyOTP(ctx context.Context, phone, code string) error {
	// Get OTP from Redis
	otpKey := fmt.Sprintf("otp:%s", phone)
	storedCode, err := database.Get(ctx, otpKey)
	if err != nil {
		return appErrors.ErrOTPExpired
	}

	// Check attempts (max 3)
	attemptsKey := fmt.Sprintf("otp_attempts:%s", phone)
	attempts, err := database.Get(ctx, attemptsKey)
	attemptCount := 0
	if err == nil {
		fmt.Sscanf(attempts, "%d", &attemptCount)
	}
	if attemptCount >= 3 {
		database.Delete(ctx, otpKey) // Delete OTP after max attempts
		return appErrors.ErrTooManyAttempts
	}

	// Verify code
	if storedCode != code {
		// Increment attempts
		database.Increment(ctx, attemptsKey)
		database.Set(ctx, attemptsKey, "1", 10*time.Minute)
		return appErrors.ErrOTPInvalid
	}

	// Mark user as verified
	user, err := s.repo.GetUserByPhone(phone)
	if err != nil {
		return err
	}

	user.IsVerified = true
	if err := s.repo.UpdateUser(user); err != nil {
		return fmt.Errorf("failed to verify user: %w", err)
	}

	// Delete OTP and attempts from Redis
	database.Delete(ctx, otpKey)
	database.Delete(ctx, attemptsKey)

	return nil
}

// RefreshToken refreshes an access token using a refresh token
func (s *Service) RefreshToken(ctx context.Context, refreshToken string) (string, error) {
	// Validate refresh token
	claims, err := utils.ValidateToken(refreshToken, s.config.JWTRefreshSecret)
	if err != nil {
		return "", appErrors.ErrInvalidToken
	}

	// Check if session exists in Redis
	sessionKey := fmt.Sprintf("session:%s", claims.UserID)
	exists, err := database.Exists(ctx, sessionKey)
	if err != nil || !exists {
		return "", appErrors.ErrInvalidToken
	}

	// Get user
	user, err := s.repo.GetUserByID(claims.UserID)
	if err != nil {
		return "", err
	}

	// Generate new access token
	accessToken, err := utils.GenerateAccessToken(user.ID.String(), user.Email, s.config.JWTSecret)
	if err != nil {
		return "", fmt.Errorf("failed to generate access token: %w", err)
	}

	return accessToken, nil
}

// Logout logs out a user by removing their session
func (s *Service) Logout(ctx context.Context, userID string) error {
	sessionKey := fmt.Sprintf("session:%s", userID)
	return database.Delete(ctx, sessionKey)
}

// GetCurrentUser retrieves the current user by ID
func (s *Service) GetCurrentUser(userID string) (*UserDTO, error) {
	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return nil, err
	}
	dto := s.userToDTO(user)
	return &dto, nil
}

// userToDTO converts a User model to UserDTO
func (s *Service) userToDTO(user *models.User) UserDTO {
	return UserDTO{
		ID:              user.ID.String(),
		Email:           user.Email,
		Phone:           user.Phone,
		FullName:        user.FullName,
		Gender:          user.Gender,
		DOB:             formatTime(user.DOB),
		ProfilePhotoURL: user.ProfilePhotoURL,
		IsVerified:      user.IsVerified,
		IsDealer:        user.IsDealer,
	}
}

func formatTime(t *time.Time) *string {
	if t == nil {
		return nil
	}
	s := t.Format("2006-01-02")
	return &s
}

// UpdateProfile updates the user's profile
func (s *Service) UpdateProfile(ctx context.Context, userID string, req *UpdateProfileRequest) (*UserDTO, error) {
	// Get user
	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if req.FullName != nil {
		user.FullName = utils.SanitizeString(*req.FullName)
	}
	if req.Gender != nil {
		user.Gender = req.Gender
	}
	if req.DOB != nil {
		dob, err := time.Parse("2006-01-02", *req.DOB)
		if err == nil {
			user.DOB = &dob
		}
	}
	if req.ProfilePhotoURL != nil {
		user.ProfilePhotoURL = req.ProfilePhotoURL
	}

	// Save updates
	if err := s.repo.UpdateUser(user); err != nil {
		return nil, err
	}

	dto := s.userToDTO(user)
	return &dto, nil
}

// ChangePassword changes the user's password
// Security: Verifies current password, validates new password strength, ensures new != current
func (s *Service) ChangePassword(ctx context.Context, userID string, req *ChangePasswordRequest) error {
	// Get user from database
	user, err := s.repo.GetUserByID(userID)
	if err != nil {
		return appErrors.ErrNotFound
	}

	// Verify current password (timing-safe comparison via bcrypt)
	if !utils.CheckPassword(req.CurrentPassword, user.PasswordHash) {
		return appErrors.ErrCurrentPasswordIncorrect
	}

	// Validate new password strength
	if err := utils.ValidatePassword(req.NewPassword); err != nil {
		return appErrors.ErrWeakPassword
	}

	// Ensure new password is different from current
	if utils.CheckPassword(req.NewPassword, user.PasswordHash) {
		return appErrors.ErrPasswordSameAsCurrent
	}

	// Hash new password with bcrypt
	newPasswordHash, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		return fmt.Errorf("failed to hash new password: %w", err)
	}

	// Update password in database
	if err := s.repo.UpdateUserPassword(userID, newPasswordHash); err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}

	return nil
}
