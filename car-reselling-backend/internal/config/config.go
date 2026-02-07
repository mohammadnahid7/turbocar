package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the application
type Config struct {
	ServerPort       string
	DatabaseURL      string
	RedisURL         string
	JWTSecret        string
	JWTRefreshSecret string
	Environment      string

	// Twilio (optional)
	TwilioAccountSID  string
	TwilioAuthToken   string
	TwilioPhoneNumber string

	// Cloudflare R2 Storage
	R2AccountID       string
	R2AccessKeyID     string
	R2SecretAccessKey string
	R2BucketName      string
	R2PublicURL       string // Optional custom domain

	// Firebase Cloud Messaging
	FirebaseCredentialsJSON string // JSON string of service account credentials
	FirebaseCredentialsPath string // Path to service account JSON file
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Try multiple paths for .env file
	envPaths := []string{
		".env",
		"../.env",
		filepath.Join(os.Getenv("GOPATH"), "src", "car-reselling-backend", ".env"),
	}

	envLoaded := false
	for _, path := range envPaths {
		if err := godotenv.Load(path); err == nil {
			fmt.Printf("✓ Loaded .env from: %s\n", path)
			envLoaded = true
			break
		}
	}

	if !envLoaded {
		fmt.Println("⚠ Warning: No .env file found, using environment variables only")
	}

	cfg := &Config{
		ServerPort:        getEnv("SERVER_PORT", "3000"),
		DatabaseURL:       getEnv("DATABASE_URL", ""),
		RedisURL:          getEnv("REDIS_URL", "redis://localhost:6379/0"),
		JWTSecret:         getEnv("JWT_SECRET", ""),
		JWTRefreshSecret:  getEnv("JWT_REFRESH_SECRET", ""),
		Environment:       getEnv("ENVIRONMENT", "development"),
		TwilioAccountSID:  getEnv("TWILIO_ACCOUNT_SID", ""),
		TwilioAuthToken:   getEnv("TWILIO_AUTH_TOKEN", ""),
		TwilioPhoneNumber: getEnv("TWILIO_PHONE_NUMBER", ""),

		// R2 Configuration
		R2AccountID:       getEnv("R2_ACCOUNT_ID", ""),
		R2AccessKeyID:     getEnv("R2_ACCESS_KEY_ID", ""),
		R2SecretAccessKey: getEnv("R2_SECRET_ACCESS_KEY", ""),
		R2BucketName:      getEnv("R2_BUCKET_NAME", ""),
		R2PublicURL:       getEnv("R2_PUBLIC_URL", ""),

		// Firebase Configuration
		FirebaseCredentialsJSON: getEnv("FIREBASE_CREDENTIALS_JSON", ""),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
	}

	// Validate required fields
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}
	if cfg.JWTRefreshSecret == "" {
		return nil, fmt.Errorf("JWT_REFRESH_SECRET is required")
	}

	// Debug: Print R2 config (hide sensitive data)
	cfg.PrintR2Config()

	return cfg, nil
}

// PrintR2Config prints R2 configuration for debugging (hides secrets)
func (c *Config) PrintR2Config() {
	fmt.Println("\n=== R2 Configuration ===")
	fmt.Printf("Account ID:     %s\n", maskString(c.R2AccountID))
	fmt.Printf("Access Key ID:  %s\n", maskString(c.R2AccessKeyID))
	fmt.Printf("Secret Key:     %s\n", maskString(c.R2SecretAccessKey))
	fmt.Printf("Bucket Name:    %s\n", c.R2BucketName)
	fmt.Printf("Public URL:     %s\n", c.R2PublicURL)
	fmt.Printf("Endpoint:       %s\n", c.GetR2Endpoint())
	fmt.Println("========================")
}

// GetR2Endpoint returns the R2 S3-compatible endpoint URL
func (c *Config) GetR2Endpoint() string {
	if c.R2AccountID == "" {
		return ""
	}
	return fmt.Sprintf("https://%s.r2.cloudflarestorage.com", c.R2AccountID)
}

// GetR2PublicURL returns the public URL for accessing images
func (c *Config) GetR2PublicURL() string {
	if c.R2PublicURL != "" {
		return c.R2PublicURL
	}
	// Default: Use R2.dev public URL (requires public bucket)
	return fmt.Sprintf("https://pub-%s.r2.dev", c.R2AccountID)
}

// ValidateR2Config checks if R2 credentials are properly configured
func (c *Config) ValidateR2Config() error {
	if c.R2AccountID == "" {
		return fmt.Errorf("R2_ACCOUNT_ID is not set")
	}
	if c.R2AccessKeyID == "" {
		return fmt.Errorf("R2_ACCESS_KEY_ID is not set")
	}
	if c.R2SecretAccessKey == "" {
		return fmt.Errorf("R2_SECRET_ACCESS_KEY is not set")
	}
	if c.R2BucketName == "" {
		return fmt.Errorf("R2_BUCKET_NAME is not set")
	}
	return nil
}

// getEnv retrieves an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// maskString hides most of the string for security
func maskString(s string) string {
	if s == "" {
		return "(empty)"
	}
	if len(s) <= 8 {
		return s[:2] + "***"
	}
	return s[:4] + "..." + s[len(s)-4:]
}
