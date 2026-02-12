package chat

import (
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Hub maintains the set of active clients and broadcasts messages
type Hub struct {
	// Registered clients by user ID
	clients map[uuid.UUID]*Client

	// Register requests from clients
	register chan *Client

	// Unregister requests from clients
	unregister chan *Client

	// Inbound messages from clients
	broadcast chan *WSMessage

	// Mutex for thread-safe operations
	mu sync.RWMutex

	// Chat service for persistence and notifications
	service *Service
}

// NewHub creates a new Hub instance
func NewHub(service *Service) *Hub {
	return &Hub{
		clients:    make(map[uuid.UUID]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan *WSMessage),
		service:    service,
	}
}

// Run starts the hub's main loop
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.UserID] = client
			h.mu.Unlock()
			log.Printf("Client registered: %s", client.UserID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.UserID]; ok {
				delete(h.clients, client.UserID)
				close(client.send)
			}
			h.mu.Unlock()
			log.Printf("Client unregistered: %s", client.UserID)

		case message := <-h.broadcast:
			h.handleBroadcast(message)
		}
	}
}

// handleBroadcast routes a message to appropriate recipients
func (h *Hub) handleBroadcast(msg *WSMessage) {
	// Get conversation participants
	participants, err := h.service.GetParticipantIDs(msg.ConversationID)
	if err != nil {
		log.Printf("Error getting participants: %v", err)
		return
	}

	// Track who received the message in real-time
	var offlineUsers []uuid.UUID

	h.mu.RLock()
	for _, userID := range participants {
		if userID == msg.SenderID {
			continue // Don't send to sender
		}

		if client, ok := h.clients[userID]; ok {
			select {
			case client.send <- msg:
				// Message sent successfully
				// For new messages, also send unread count update and conversation update
				if msg.Type == "message" {
					go h.sendUnreadUpdateToClient(client, userID)
					go h.sendConversationUpdate(client, msg)
				}
			default:
				// Client buffer full, consider them offline
				offlineUsers = append(offlineUsers, userID)
			}
		} else {
			// User not connected
			offlineUsers = append(offlineUsers, userID)
		}
	}
	h.mu.RUnlock()

	// Send push notifications to offline users
	if len(offlineUsers) > 0 {
		go h.service.SendPushNotifications(offlineUsers, msg)
	}

	// Also notify sender about conversation update (for chat list refresh)
	if msg.Type == "message" {
		h.mu.RLock()
		if senderClient, ok := h.clients[msg.SenderID]; ok {
			go h.sendConversationUpdate(senderClient, msg)
		}
		h.mu.RUnlock()
	}
}

// sendConversationUpdate notifies client that a conversation was updated
func (h *Hub) sendConversationUpdate(client *Client, msg *WSMessage) {
	updateMsg := &WSMessage{
		Type:           "conversation:updated",
		ConversationID: msg.ConversationID,
		SenderID:       msg.SenderID,
		Content:        msg.Content,
		MessageType:    msg.MessageType,
		Timestamp:      msg.Timestamp,
	}
	select {
	case client.send <- updateMsg:
		// Sent successfully
	default:
		// Buffer full, skip
	}
}

// sendUnreadUpdateToClient sends total unread count to a specific client
func (h *Hub) sendUnreadUpdateToClient(client *Client, userID uuid.UUID) {
	total, err := h.service.GetTotalUnreadCount(userID)
	if err != nil {
		log.Printf("Failed to get total unread count: %v", err)
		return
	}
	unreadMsg := &WSMessage{
		Type:      "unread:update",
		Content:   fmt.Sprintf("%d", total),
		Timestamp: time.Now(),
	}
	select {
	case client.send <- unreadMsg:
		// Sent successfully
	default:
		// Buffer full, skip
	}
}

// SendUnreadUpdate sends unread update to a specific user if they're online
func (h *Hub) SendUnreadUpdate(userID uuid.UUID) {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if ok {
		go h.sendUnreadUpdateToClient(client, userID)
	}
}

// IsUserOnline checks if a user is currently connected
func (h *Hub) IsUserOnline(userID uuid.UUID) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

// GetOnlineCount returns the number of connected clients
func (h *Hub) GetOnlineCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// SendNotification sends a notification to a specific user via WebSocket
// Returns true if the user was online and notification was sent, false otherwise
func (h *Hub) SendNotification(userID uuid.UUID, notificationData map[string]interface{}) bool {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return false
	}

	msg := &WSMessage{
		Type:      "notification",
		Data:      notificationData,
		Timestamp: time.Now(),
	}

	select {
	case client.send <- msg:
		return true
	default:
		// Buffer full, couldn't send
		return false
	}
}

// SendNotificationCount sends the unread notification count to a specific user
func (h *Hub) SendNotificationCount(userID uuid.UUID, count int64) bool {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return false
	}

	msg := &WSMessage{
		Type: "notification:unread",
		Data: map[string]interface{}{
			"count": count,
		},
		Timestamp: time.Now(),
	}

	select {
	case client.send <- msg:
		return true
	default:
		return false
	}
}
