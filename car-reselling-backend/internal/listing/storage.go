package listing

import (
	"bytes"
	"context"
	"fmt"
	"image"
	"image/jpeg"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/disintegration/imaging"
	"github.com/google/uuid"

	"github.com/yourusername/car-reselling-backend/internal/config"
)

// StorageService defines the interface for file operations
type StorageService interface {
	UploadImage(ctx context.Context, file multipart.File, filename string) (string, error)
	UploadMultipleImages(ctx context.Context, files []*multipart.FileHeader, carID string) ([]string, error)
	DeleteImage(ctx context.Context, imageURL string) error
	DeleteMultipleImages(ctx context.Context, imageURLs []string) error
}

// R2StorageService implements StorageService using Cloudflare R2
type R2StorageService struct {
	client    *s3.Client
	bucket    string
	publicURL string
}

// NewStorageService creates a new R2StorageService
func NewStorageService(cfg *config.Config) (*R2StorageService, error) {
	// Validate R2 configuration
	if err := cfg.ValidateR2Config(); err != nil {
		return nil, fmt.Errorf("R2 config validation failed: %v", err)
	}

	fmt.Println("Initializing R2 Storage Service...")

	// Create static credentials provider
	staticCreds := credentials.NewStaticCredentialsProvider(
		cfg.R2AccessKeyID,
		cfg.R2SecretAccessKey,
		"", // Session token (not used for R2)
	)

	// Load AWS SDK config with custom settings for R2
	awsCfg, err := awsconfig.LoadDefaultConfig(context.TODO(),
		awsconfig.WithCredentialsProvider(staticCreds),
		awsconfig.WithRegion("auto"), // R2 requires region but doesn't use it
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %v", err)
	}

	// Create S3 client with R2 endpoint
	endpoint := cfg.GetR2Endpoint()
	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true // Required for R2
	})

	// Test connection by listing bucket (optional but helpful for debugging)
	_, err = client.HeadBucket(context.TODO(), &s3.HeadBucketInput{
		Bucket: aws.String(cfg.R2BucketName),
	})
	if err != nil {
		fmt.Printf("⚠ Warning: Could not verify bucket '%s': %v\n", cfg.R2BucketName, err)
		fmt.Println("  This may be a permissions issue or the bucket doesn't exist.")
		// Don't fail - bucket might have restricted HeadBucket permissions
	} else {
		fmt.Printf("✓ R2 Bucket '%s' verified successfully\n", cfg.R2BucketName)
	}

	publicURL := cfg.GetR2PublicURL()
	fmt.Printf("✓ R2 Storage Service initialized (Public URL: %s)\n", publicURL)

	return &R2StorageService{
		client:    client,
		bucket:    cfg.R2BucketName,
		publicURL: publicURL,
	}, nil
}

// UploadImage uploads a single image to R2
func (s *R2StorageService) UploadImage(ctx context.Context, file multipart.File, filename string) (string, error) {
	// Read file content
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %v", err)
	}

	// Detect content type
	contentType := http.DetectContentType(fileBytes)
	if !strings.HasPrefix(contentType, "image/") {
		return "", fmt.Errorf("file is not an image: %s", contentType)
	}

	// Generate unique key
	ext := filepath.Ext(filename)
	if ext == "" {
		ext = ".jpg"
	}
	key := fmt.Sprintf("cars/%s-%d%s", uuid.New().String(), time.Now().UnixNano(), ext)

	// Upload to R2
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(fileBytes),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to R2: %v", err)
	}

	// Return public URL
	return fmt.Sprintf("%s/%s", s.publicURL, key), nil
}

// UploadMultipleImages uploads multiple images and returns their URLs
func (s *R2StorageService) UploadMultipleImages(ctx context.Context, files []*multipart.FileHeader, carID string) ([]string, error) {
	if len(files) == 0 {
		return nil, fmt.Errorf("no files provided")
	}

	var urls []string

	for i, fileHeader := range files {
		// Validate file size (max 10MB)
		if fileHeader.Size > 10*1024*1024 {
			return urls, fmt.Errorf("file %s exceeds 10MB limit", fileHeader.Filename)
		}

		// Validate file extension
		ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
		if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
			return urls, fmt.Errorf("file %s has invalid type (allowed: jpg, jpeg, png, webp)", fileHeader.Filename)
		}

		// Open file
		file, err := fileHeader.Open()
		if err != nil {
			return urls, fmt.Errorf("failed to open file %s: %v", fileHeader.Filename, err)
		}
		defer file.Close()

		// Read and decode image
		fileBytes, err := io.ReadAll(file)
		if err != nil {
			return urls, fmt.Errorf("failed to read file %s: %v", fileHeader.Filename, err)
		}

		// Decode image for resizing
		img, _, err := image.Decode(bytes.NewReader(fileBytes))
		if err != nil {
			// If decoding fails, upload original
			fmt.Printf("Warning: Could not decode image %s for resizing, uploading original\n", fileHeader.Filename)
			url, err := s.uploadBytes(ctx, fileBytes, carID, i, ext)
			if err != nil {
				return urls, err
			}
			urls = append(urls, url)
			continue
		}

		// Resize image (max 1920x1080)
		resizedImg := imaging.Fit(img, 1920, 1080, imaging.Lanczos)

		// Encode to JPEG
		buf := new(bytes.Buffer)
		if err := jpeg.Encode(buf, resizedImg, &jpeg.Options{Quality: 85}); err != nil {
			return urls, fmt.Errorf("failed to encode image: %v", err)
		}

		// Upload resized image
		url, err := s.uploadBytes(ctx, buf.Bytes(), carID, i, ".jpg")
		if err != nil {
			return urls, err
		}
		urls = append(urls, url)

		fmt.Printf("✓ Uploaded image %d/%d for car %s\n", i+1, len(files), carID)
	}

	return urls, nil
}

// uploadBytes uploads raw bytes to R2
func (s *R2StorageService) uploadBytes(ctx context.Context, data []byte, carID string, index int, ext string) (string, error) {
	timestamp := time.Now().UnixNano()
	key := fmt.Sprintf("cars/%s/%d-%d%s", carID, index+1, timestamp, ext)

	contentType := "image/jpeg"
	if ext == ".png" {
		contentType = "image/png"
	} else if ext == ".webp" {
		contentType = "image/webp"
	}

	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String(contentType),
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload to R2: %v", err)
	}

	return fmt.Sprintf("%s/%s", s.publicURL, key), nil
}

// DeleteImage deletes an image from R2
func (s *R2StorageService) DeleteImage(ctx context.Context, imageURL string) error {
	// Extract key from URL
	key := strings.TrimPrefix(imageURL, s.publicURL+"/")
	if key == imageURL {
		return fmt.Errorf("invalid image URL: %s", imageURL)
	}

	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete from R2: %v", err)
	}

	return nil
}

// DeleteMultipleImages deletes multiple images from R2
func (s *R2StorageService) DeleteMultipleImages(ctx context.Context, imageURLs []string) error {
	for _, url := range imageURLs {
		if err := s.DeleteImage(ctx, url); err != nil {
			// Log error but continue with other deletions
			fmt.Printf("Warning: Failed to delete image %s: %v\n", url, err)
		}
	}
	return nil
}

// NullStorageService is a no-op storage service for when R2 is not configured
type NullStorageService struct{}

func (s *NullStorageService) UploadImage(ctx context.Context, file multipart.File, filename string) (string, error) {
	return "", fmt.Errorf("storage service not configured")
}

func (s *NullStorageService) UploadMultipleImages(ctx context.Context, files []*multipart.FileHeader, carID string) ([]string, error) {
	return nil, fmt.Errorf("storage service not configured")
}

func (s *NullStorageService) DeleteImage(ctx context.Context, imageURL string) error {
	return nil
}

func (s *NullStorageService) DeleteMultipleImages(ctx context.Context, imageURLs []string) error {
	return nil
}
