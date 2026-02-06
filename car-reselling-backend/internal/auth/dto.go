package auth

// RegisterRequest represents the registration request
// @Description Registration request with user details
type RegisterRequest struct {
	Email    string  `json:"email" binding:"required,email" example:"user@example.com"`
	Phone    string  `json:"phone" binding:"required" example:"+1234567890"`
	Password string  `json:"password" binding:"required,min=8" example:"SecurePass123"`
	FullName string  `json:"full_name" binding:"required" example:"John Doe"`
	Gender   *string `json:"gender" example:"male"`
	DOB      *string `json:"dob" example:"1990-01-01"`
}

// LoginRequest represents the login request
// @Description Login request with email/phone and password
type LoginRequest struct {
	EmailOrPhone string `json:"email_or_phone" binding:"required" example:"user@example.com"`
	Password     string `json:"password" binding:"required" example:"SecurePass123"`
}

// SendOTPRequest represents the send OTP request
// @Description Request to send OTP to phone number
type SendOTPRequest struct {
	Phone string `json:"phone" binding:"required" example:"+1234567890"`
}

// VerifyOTPRequest represents the verify OTP request
// @Description Request to verify OTP code
type VerifyOTPRequest struct {
	Phone string `json:"phone" binding:"required" example:"+1234567890"`
	Code  string `json:"code" binding:"required,len=6" example:"123456"`
}

// RefreshTokenRequest represents the refresh token request
// @Description Request to refresh access token
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
}

// AuthResponse represents the authentication response
// @Description Authentication response with tokens and user data
type AuthResponse struct {
	AccessToken  string  `json:"access_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
	RefreshToken string  `json:"refresh_token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`
	User         UserDTO `json:"user"`
}

// UserDTO represents user data in API responses
// @Description User information in API responses
type UserDTO struct {
	ID              string  `json:"id" example:"550e8400-e29b-41d4-a716-446655440000"`
	Email           string  `json:"email" example:"user@example.com"`
	Phone           string  `json:"phone" example:"+1234567890"`
	FullName        string  `json:"full_name" example:"John Doe"`
	Gender          *string `json:"gender" example:"male"`
	DOB             *string `json:"dob" example:"1990-01-01T00:00:00Z"`
	ProfilePhotoURL *string `json:"profile_photo_url" example:"https://example.com/photo.jpg"`
	IsVerified      bool    `json:"is_verified" example:"true"`
	IsDealer        bool    `json:"is_dealer" example:"false"`
}

// UpdateProfileRequest represents the update profile request
// @Description Request to update user profile
type UpdateProfileRequest struct {
	FullName        *string `json:"full_name" example:"John Doe"`
	Gender          *string `json:"gender" example:"male"`
	DOB             *string `json:"dob" example:"1990-01-01"`
	ProfilePhotoURL *string `json:"profile_photo_url" example:"https://example.com/photo.jpg"`
}

// MessageResponse represents a simple message response
// @Description Simple message response
type MessageResponse struct {
	Message string `json:"message" example:"Operation successful"`
}

// ChangePasswordRequest represents the change password request
// @Description Request to change user password
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required" example:"OldPassword123!"`
	NewPassword     string `json:"new_password" binding:"required,min=8" example:"NewPassword123!"`
}
