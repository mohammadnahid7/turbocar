package chat

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for now; tighten in production
	},
}

// Handler handles HTTP requests for chatsa
type Handler struct {
	hub     *Hub
	service *Service
}

// NewHandler creates a new chat handler
func NewHandler(hub *Hub, service *Service) *Handler {
	return &Handler{
		hub:     hub,
		service: service,
	}
}

// RegisterRoutes registers chat routes with the router
func (h *Handler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	chat := router.Group("/chat")
	chat.Use(authMiddleware)
	{
		chat.GET("/ws", h.HandleWebSocket)
		chat.GET("/conversations", h.GetConversations)
		chat.POST("/conversations", h.StartConversation)
		chat.GET("/conversations/:id/messages", h.GetMessages)
		chat.PUT("/conversations/:id/read", h.MarkAsRead)
		chat.POST("/device", h.RegisterDevice)
		chat.DELETE("/device", h.UnregisterDevice)
	}
}

// HandleWebSocket upgrades HTTP to WebSocket connection
// @Summary Connect to chat WebSocket
// @Tags Chat
// @Param token query string true "JWT token for authentication"
// @Success 101 {string} string "Switching Protocols"
// @Router /chat/ws [get]
func (h *Handler) HandleWebSocket(c *gin.Context) {
	// Get user ID from auth middleware context
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	userID, ok := userIDVal.(uuid.UUID)
	if !ok {
		// Try parsing from string
		userIDStr, ok := userIDVal.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			return
		}
		var err error
		userID, err = uuid.Parse(userIDStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID format"})
			return
		}
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upgrade connection"})
		return
	}

	client := NewClient(h.hub, conn, userID)
	h.hub.register <- client

	// Start read/write pumps in goroutines
	go client.WritePump()
	go client.ReadPump()
}

// GetConversations returns all conversations for the authenticated user
// @Summary Get user's conversations
// @Tags Chat
// @Security BearerAuth
// @Success 200 {array} ConversationResponse
// @Router /chat/conversations [get]
func (h *Handler) GetConversations(c *gin.Context) {
	userID := h.getUserID(c)
	log.Println("Nahid: Conversations: ", userID)
	if userID == uuid.Nil {
		return
	}

	conversations, err := h.service.GetUserConversations(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get conversations"})
		return
	}
	c.JSON(http.StatusOK, conversations)
}

// StartConversation creates a new conversation
// @Summary Start a new conversation
// @Tags Chat
// @Security BearerAuth
// @Param request body StartConversationRequest true "Participant IDs"
// @Success 201 {object} Conversation
// @Router /chat/conversations [post]
func (h *Handler) StartConversation(c *gin.Context) {
	userID := h.getUserID(c)
	log.Println("Nahid: User ID: ", userID)
	if userID == uuid.Nil {
		return
	}

	// Parse request body
	var req StartConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("Error binding JSON: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// DEBUG: Log received request data
	log.Printf("DEBUG StartConversation - Request received:")
	log.Printf("  ParticipantIDs: %v", req.ParticipantIDs)
	log.Printf("  CarID: %v", req.CarID)
	log.Printf("  CarTitle: %v", req.CarTitle)
	log.Printf("  Context: %v", req.Context)

	// Include the current user in participants
	participantIDs := append(req.ParticipantIDs, userID)

	conversation, err := h.service.StartConversation(participantIDs, req.CarID, req.CarTitle, req.Context)
	if err != nil {
		log.Printf("Error creating conversation: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create conversation"})
		return
	}

	// DEBUG: Log response data
	log.Printf("DEBUG StartConversation - Response sent:")
	log.Printf("  Conversation ID: %v", conversation.ID)
	log.Printf("  CarID: %v", conversation.CarID)
	log.Printf("  CarTitle: %v", conversation.CarTitle)

	c.JSON(http.StatusCreated, conversation)
}

// GetMessages returns message history for a conversation
// @Summary Get chat history
// @Tags Chat
// @Security BearerAuth
// @Param id path string true "Conversation ID"
// @Param page query int false "Page number" default(1)
// @Param page_size query int false "Page size" default(50)
// @Success 200 {object} ChatHistoryResponse
// @Router /chat/conversations/{id}/messages [get]
func (h *Handler) GetMessages(c *gin.Context) {
	// sdswqeqw
	userID := h.getUserID(c)
	if userID == uuid.Nil {
		return
	}

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}

	history, err := h.service.GetChatHistory(conversationID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get messages"})
		return
	}

	c.JSON(http.StatusOK, history)
}

// MarkAsRead marks messages in a conversation as read
// @Summary Mark messages as read
// @Tags Chat
// @Security BearerAuth
// @Param id path string true "Conversation ID"
// @Param request body object{message_id=string} true "Message ID to mark as read"
// @Success 200 {object} object{message=string}
// @Router /chat/conversations/{id}/read [put]
func (h *Handler) MarkAsRead(c *gin.Context) {
	userID := h.getUserID(c)
	if userID == uuid.Nil {
		return
	}

	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	var req struct {
		MessageID string `json:"message_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.MarkAsRead(userID, conversationID, req.MessageID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark messages as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Messages marked as read"})
}

// RegisterDevice stores FCM token for push notifications
// @Summary Register device for push notifications
// @Tags Chat
// @Security BearerAuth
// @Param request body object{fcm_token=string,device_type=string} true "Device info"
// @Success 200 {object} object{message=string}
// @Router /chat/device [post]
func (h *Handler) RegisterDevice(c *gin.Context) {
	userID := h.getUserID(c)
	if userID == uuid.Nil {
		return
	}

	var req struct {
		FCMToken   string `json:"fcm_token" binding:"required"`
		DeviceType string `json:"device_type"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.DeviceType == "" {
		req.DeviceType = "android"
	}

	if err := h.service.RegisterDevice(userID, req.FCMToken, req.DeviceType); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register device"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Device registered successfully"})
}

// UnregisterDevice removes FCM token
// @Summary Unregister device from push notifications
// @Tags Chat
// @Security BearerAuth
// @Param request body object{fcm_token=string} true "FCM token"
// @Success 200 {object} object{message=string}
// @Router /chat/device [delete]
func (h *Handler) UnregisterDevice(c *gin.Context) {
	userID := h.getUserID(c)
	if userID == uuid.Nil {
		return
	}

	var req struct {
		FCMToken string `json:"fcm_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.UnregisterDevice(userID, req.FCMToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unregister device"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Device unregistered successfully"})
}

// getUserID extracts user ID from context
func (h *Handler) getUserID(c *gin.Context) uuid.UUID {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return uuid.Nil
	}

	switch v := userIDVal.(type) {
	case uuid.UUID:
		return v
	case string:
		id, err := uuid.Parse(v)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
			return uuid.Nil
		}
		return id
	default:
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID type"})
		return uuid.Nil
	}
}
