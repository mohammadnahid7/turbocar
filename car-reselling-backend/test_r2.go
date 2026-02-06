package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/joho/godotenv"
)

func main() {
	fmt.Println("=== R2 Diagnostic Test ===\n")

	// Step 1: Load .env
	fmt.Println("Step 1: Loading .env file...")
	if err := godotenv.Load(); err != nil {
		log.Printf("❌ Failed to load .env: %v\n", err)
		fmt.Println("   Make sure .env exists in the current directory")
		os.Exit(1)
	}
	fmt.Println("✅ .env file loaded successfully\n")

	// Step 2: Read environment variables
	fmt.Println("Step 2: Reading environment variables...")
	accountID := os.Getenv("R2_ACCOUNT_ID")
	accessKeyID := os.Getenv("R2_ACCESS_KEY_ID")
	secretAccessKey := os.Getenv("R2_SECRET_ACCESS_KEY")
	bucketName := os.Getenv("R2_BUCKET_NAME")
	publicURL := os.Getenv("R2_PUBLIC_URL")

	// Print values (masked)
	fmt.Printf("   R2_ACCOUNT_ID:        %s\n", maskString(accountID))
	fmt.Printf("   R2_ACCESS_KEY_ID:     %s\n", maskString(accessKeyID))
	fmt.Printf("   R2_SECRET_ACCESS_KEY: %s\n", maskString(secretAccessKey))
	fmt.Printf("   R2_BUCKET_NAME:       %s\n", bucketName)
	fmt.Printf("   R2_PUBLIC_URL:        %s\n", publicURL)
	fmt.Println()

	// Step 3: Validate required variables
	fmt.Println("Step 3: Validating required variables...")
	errors := []string{}
	if accountID == "" {
		errors = append(errors, "R2_ACCOUNT_ID is empty")
	}
	if accessKeyID == "" {
		errors = append(errors, "R2_ACCESS_KEY_ID is empty")
	}
	if secretAccessKey == "" {
		errors = append(errors, "R2_SECRET_ACCESS_KEY is empty")
	}
	if bucketName == "" {
		errors = append(errors, "R2_BUCKET_NAME is empty")
	}

	if len(errors) > 0 {
		fmt.Println("❌ Validation failed:")
		for _, e := range errors {
			fmt.Printf("   - %s\n", e)
		}
		os.Exit(1)
	}
	fmt.Println("✅ All required variables are set\n")

	// Step 4: Build endpoint
	fmt.Println("Step 4: Building R2 endpoint...")
	endpoint := fmt.Sprintf("https://%s.r2.cloudflarestorage.com", accountID)
	fmt.Printf("   Endpoint: %s\n\n", endpoint)

	// Step 5: Create S3 client
	fmt.Println("Step 5: Creating S3 client...")
	creds := credentials.NewStaticCredentialsProvider(accessKeyID, secretAccessKey, "")
	cfg, err := awsconfig.LoadDefaultConfig(context.TODO(),
		awsconfig.WithCredentialsProvider(creds),
		awsconfig.WithRegion("auto"),
	)
	if err != nil {
		log.Printf("❌ Failed to load AWS config: %v\n", err)
		os.Exit(1)
	}

	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})
	fmt.Println("✅ S3 client created\n")

	// Step 6: Test bucket access
	fmt.Println("Step 6: Testing bucket access (ListObjectsV2)...")
	result, err := client.ListObjectsV2(context.TODO(), &s3.ListObjectsV2Input{
		Bucket:  aws.String(bucketName),
		MaxKeys: aws.Int32(5),
	})
	if err != nil {
		log.Printf("❌ Bucket access failed: %v\n", err)
		fmt.Println("\n   Possible causes:")
		fmt.Println("   1. Wrong Account ID or bucket name")
		fmt.Println("   2. Invalid API token credentials")
		fmt.Println("   3. Token does not have permission for this bucket")
		fmt.Println("   4. Bucket does not exist\n")
		fmt.Println("   Fix: Go to Cloudflare Dashboard > R2 and verify:")
		fmt.Println("   - Bucket 'turbo-car-images' exists")
		fmt.Println("   - API token has 'Object Read & Write' permission")
		os.Exit(1)
	}

	fmt.Printf("✅ Bucket access successful! Found %d objects\n", len(result.Contents))
	if len(result.Contents) > 0 {
		fmt.Println("   Recent objects:")
		for _, obj := range result.Contents {
			fmt.Printf("   - %s\n", *obj.Key)
		}
	}
	fmt.Println()

	// Step 7: Public URL check
	fmt.Println("Step 7: Checking R2_PUBLIC_URL...")
	if publicURL == "" {
		fmt.Println("⚠️  R2_PUBLIC_URL is empty!")
		fmt.Println("   This will cause image URLs to be incorrect.")
		fmt.Println("\n   Fix:")
		fmt.Println("   1. Go to Cloudflare Dashboard > R2 > turbo-car-images > Settings")
		fmt.Println("   2. Enable 'Public Development URL'")
		fmt.Println("   3. Copy the URL (looks like: https://pub-xxxxxx.r2.dev)")
		fmt.Println("   4. Add to .env: R2_PUBLIC_URL=https://pub-xxxxxx.r2.dev")
	} else {
		fmt.Println("✅ R2_PUBLIC_URL is set")
	}

	fmt.Println("\n=================================")
	fmt.Println("🎉 R2 Configuration is WORKING!")
	fmt.Println("=================================")
	fmt.Println("\nIf your app still shows 'Storage Service not configured',")
	fmt.Println("restart your server: go run cmd/api/main.go")
}

func maskString(s string) string {
	if s == "" {
		return "(empty)"
	}
	if len(s) <= 8 {
		return s[:2] + "***"
	}
	return s[:4] + "..." + s[len(s)-4:]
}
