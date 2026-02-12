package notification

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"github.com/yourusername/car-reselling-backend/internal/config"
	"google.golang.org/api/option"
	"gorm.io/gorm"
)

// FCMClient implements the FCMService interface for sending push notifications
type FCMClient struct {
	client *messaging.Client
	db     *gorm.DB
}

// NewFCMClient creates a new FCM client for sending push notifications
func NewFCMClient(cfg *config.Config) (*FCMClient, error) {
	ctx := context.Background()

	// Check if Firebase credentials are configured
	if cfg.FirebaseCredentialsJSON == "" && cfg.FirebaseCredentialsPath == "" {
		return nil, fmt.Errorf("firebase credentials not configured (set FIREBASE_CREDENTIALS_JSON or FIREBASE_CREDENTIALS_PATH)")
	}

	var app *firebase.App
	var err error

	if cfg.FirebaseCredentialsJSON != "" {
		// Use JSON string from environment variable
		opt := option.WithCredentialsJSON([]byte(cfg.FirebaseCredentialsJSON))
		app, err = firebase.NewApp(ctx, nil, opt)
	} else {
		// Use file path
		opt := option.WithCredentialsFile(cfg.FirebaseCredentialsPath)
		app, err = firebase.NewApp(ctx, nil, opt)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to initialize firebase app: %w", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get firebase messaging client: %w", err)
	}

	log.Println("✓ Firebase Cloud Messaging initialized successfully")
	return &FCMClient{client: client}, nil
}

// SetDB sets the database connection for token lookups
func (f *FCMClient) SetDB(db *gorm.DB) {
	f.db = db
}

// SendToUsers sends push notifications to multiple users via FCM
func (f *FCMClient) SendToUsers(userIDs []uuid.UUID, title, body string, data map[string]string) error {
	if f.client == nil {
		return fmt.Errorf("fcm client not initialized")
	}

	if f.db == nil {
		return fmt.Errorf("database connection not set")
	}

	ctx := context.Background()

	// Get FCM tokens for these users
	var tokens []string
	err := f.db.WithContext(ctx).Table("user_devices").
		Select("fcm_token").
		Where("user_id IN ?", userIDs).
		Pluck("fcm_token", &tokens).Error
	if err != nil {
		return fmt.Errorf("failed to get fcm tokens: %w", err)
	}

	if len(tokens) == 0 {
		log.Printf("No FCM tokens found for users: %v", userIDs)
		return nil
	}

	// Send multicast message
	message := &messaging.MulticastMessage{
		Tokens: tokens,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
				ChannelID:   "price_alerts",
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-priority": "10",
			},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: title,
						Body:  body,
					},
					Sound: "default",
					Badge: func() *int { i := 1; return &i }(),
				},
			},
		},
	}

	response, err := f.client.SendEachForMulticast(ctx, message)
	if err != nil {
		return fmt.Errorf("failed to send multicast message: %w", err)
	}

	log.Printf("FCM: Sent %d/%d notifications successfully", response.SuccessCount, len(tokens))

	// Log failures for debugging
	if response.FailureCount > 0 {
		for i, resp := range response.Responses {
			if resp.Error != nil {
				log.Printf("FCM: Failed to send to token[%d]: %v", i, resp.Error)
			}
		}
	}

	return nil
}

// SendToToken sends a notification to a single FCM token
func (f *FCMClient) SendToToken(token, title, body string, data map[string]string) error {
	if f.client == nil {
		return fmt.Errorf("fcm client not initialized")
	}

	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: title,
						Body:  body,
					},
					Sound: "default",
				},
			},
		},
	}

	ctx := context.Background()
	_, err := f.client.Send(ctx, message)
	if err != nil {
		return fmt.Errorf("failed to send message: %w", err)
	}

	return nil
}
