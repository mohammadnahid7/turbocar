package errors

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Custom error types
var (
	ErrUserAlreadyExists        = errors.New("user already exists")
	ErrInvalidCredentials       = errors.New("invalid credentials")
	ErrUserNotVerified          = errors.New("user not verified")
	ErrInvalidToken             = errors.New("invalid token")
	ErrOTPExpired               = errors.New("OTP expired")
	ErrOTPInvalid               = errors.New("invalid OTP")
	ErrTooManyAttempts          = errors.New("too many attempts")
	ErrNotFound                 = errors.New("resource not found")
	ErrUnauthorized             = errors.New("unauthorized")
	ErrForbidden                = errors.New("forbidden")
	ErrInvalidEmail             = errors.New("invalid email format")
	ErrInvalidPhone             = errors.New("invalid phone number format - must start with + and country code")
	ErrCurrentPasswordIncorrect = errors.New("current password is incorrect")
	ErrPasswordSameAsCurrent    = errors.New("new password must be different from current password")
	ErrWeakPassword             = errors.New("password must be at least 8 characters with uppercase, lowercase, number, and special character")
)

// ErrorResponse represents an error response
// @Description Error response structure
type ErrorResponse struct {
	Error   string `json:"error" example:"Bad Request"`
	Message string `json:"message,omitempty" example:"Invalid input data"`
}

// HandleError handles errors and returns appropriate HTTP responses
func HandleError(c *gin.Context, err error) {
	statusCode := http.StatusInternalServerError
	message := err.Error()

	switch err {
	case ErrUserAlreadyExists:
		statusCode = http.StatusConflict
	case ErrInvalidCredentials:
		statusCode = http.StatusUnauthorized
	case ErrUserNotVerified:
		statusCode = http.StatusForbidden
	case ErrInvalidToken, ErrUnauthorized:
		statusCode = http.StatusUnauthorized
	case ErrForbidden:
		statusCode = http.StatusForbidden
	case ErrOTPExpired, ErrOTPInvalid:
		statusCode = http.StatusBadRequest
	case ErrTooManyAttempts:
		statusCode = http.StatusTooManyRequests
	case ErrNotFound:
		statusCode = http.StatusNotFound
	case ErrInvalidEmail, ErrInvalidPhone:
		statusCode = http.StatusBadRequest
	case ErrCurrentPasswordIncorrect, ErrPasswordSameAsCurrent, ErrWeakPassword:
		statusCode = http.StatusBadRequest
	}

	c.JSON(statusCode, ErrorResponse{
		Error:   http.StatusText(statusCode),
		Message: message,
	})
}

// HandleErrorWithMessage handles errors with a custom message
func HandleErrorWithMessage(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, ErrorResponse{
		Error:   http.StatusText(statusCode),
		Message: message,
	})
}
