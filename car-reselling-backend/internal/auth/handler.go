package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"

	appErrors "github.com/yourusername/car-reselling-backend/pkg/errors"
)

// ErrorResponse alias for Swagger documentation
type ErrorResponse = appErrors.ErrorResponse

// Handler handles HTTP requests for authentication
type Handler struct {
	service *Service
}

// NewHandler creates a new authentication handler
func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

// Register handles user registration
// @Summary Register a new user
// @Description Register a new user with email, phone, password, and full name
// @Tags auth
// @Accept json
// @Produce json
// @Param request body RegisterRequest true "Registration data"
// @Success 201 {object} MessageResponse
// @Failure 400 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Router /api/auth/register [post]
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.service.Register(c.Request.Context(), &req); err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusCreated, MessageResponse{
		Message: "Registration successful! You can now login with your credentials.",
	})
}

// Login handles user login
// @Summary Login user
// @Description Login with email/phone and password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body LoginRequest true "Login credentials"
// @Success 200 {object} AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 403 {object} ErrorResponse
// @Router /api/auth/login [post]
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	response, err := h.service.Login(c.Request.Context(), &req)
	if err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, response)
}

// SendOTP sends an OTP to the user's phone
// @Summary Send OTP
// @Description Send a verification OTP to the phone number
// @Tags auth
// @Accept json
// @Produce json
// @Param request body SendOTPRequest true "Phone number"
// @Success 200 {object} MessageResponse
// @Failure 400 {object} ErrorResponse
// @Failure 429 {object} ErrorResponse
// @Router /api/auth/send-otp [post]
func (h *Handler) SendOTP(c *gin.Context) {
	var req SendOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.service.SendOTP(c.Request.Context(), req.Phone); err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, MessageResponse{
		Message: "OTP sent successfully",
	})
}

// VerifyOTP verifies an OTP code
// @Summary Verify OTP
// @Description Verify the OTP code sent to the phone number
// @Tags auth
// @Accept json
// @Produce json
// @Param request body VerifyOTPRequest true "Phone and OTP code"
// @Success 200 {object} MessageResponse
// @Failure 400 {object} ErrorResponse
// @Failure 429 {object} ErrorResponse
// @Router /api/auth/verify-otp [post]
func (h *Handler) VerifyOTP(c *gin.Context) {
	var req VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.service.VerifyOTP(c.Request.Context(), req.Phone, req.Code); err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, MessageResponse{
		Message: "Phone number verified successfully",
	})
}

// RefreshToken refreshes an access token
// @Summary Refresh access token
// @Description Refresh the access token using a refresh token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body RefreshTokenRequest true "Refresh token"
// @Success 200 {object} map[string]string
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/auth/refresh [post]
func (h *Handler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	accessToken, err := h.service.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token": accessToken,
	})
}

// Logout logs out the current user
// @Summary Logout user
// @Description Logout the current user by invalidating their session
// @Tags auth
// @Security BearerAuth
// @Produce json
// @Success 200 {object} MessageResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/auth/logout [post]
func (h *Handler) Logout(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		appErrors.HandleError(c, appErrors.ErrUnauthorized)
		return
	}

	if err := h.service.Logout(c.Request.Context(), userID.(string)); err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, MessageResponse{
		Message: "Logged out successfully",
	})
}

// GetCurrentUser gets the current authenticated user
// @Summary Get current user
// @Description Get the current authenticated user's information
// @Tags auth
// @Security BearerAuth
// @Produce json
// @Success 200 {object} UserDTO
// @Failure 401 {object} ErrorResponse
// @Router /api/auth/me [get]
func (h *Handler) GetCurrentUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		appErrors.HandleError(c, appErrors.ErrUnauthorized)
		return
	}

	user, err := h.service.GetCurrentUser(userID.(string))
	if err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, user)
}

// UpdateProfile updates the current authenticated user's profile
// @Summary Update profile
// @Description Update the current authenticated user's profile information
// @Tags auth
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body UpdateProfileRequest true "Profile update data"
// @Success 200 {object} UserDTO
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/auth/me [put]
func (h *Handler) UpdateProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		appErrors.HandleError(c, appErrors.ErrUnauthorized)
		return
	}

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	user, err := h.service.UpdateProfile(c.Request.Context(), userID.(string), &req)
	if err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, user)
}

// ChangePassword changes the authenticated user's password
// @Summary Change password
// @Description Change the authenticated user's password
// @Tags auth
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param request body ChangePasswordRequest true "Password change data"
// @Success 200 {object} MessageResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/auth/change-password [post]
func (h *Handler) ChangePassword(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		appErrors.HandleError(c, appErrors.ErrUnauthorized)
		return
	}

	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		appErrors.HandleErrorWithMessage(c, http.StatusBadRequest, err.Error())
		return
	}

	if err := h.service.ChangePassword(c.Request.Context(), userID.(string), &req); err != nil {
		appErrors.HandleError(c, err)
		return
	}

	c.JSON(http.StatusOK, MessageResponse{
		Message: "Password changed successfully",
	})
}
