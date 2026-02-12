package main

import (
	"log"
	"net/http"

	cors "github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	"github.com/yourusername/car-reselling-backend/internal/auth"
	"github.com/yourusername/car-reselling-backend/internal/chat"
	"github.com/yourusername/car-reselling-backend/internal/config"
	"github.com/yourusername/car-reselling-backend/internal/database"
	"github.com/yourusername/car-reselling-backend/internal/listing"
	"github.com/yourusername/car-reselling-backend/internal/models"
	"github.com/yourusername/car-reselling-backend/internal/notification"

	_ "github.com/yourusername/car-reselling-backend/docs" // Swagger docs
)

// @title           Car Reselling Backend API
// @version         1.0
// @description     A high-performance backend for a second-hand car reselling marketplace
// @termsOfService  http://swagger.io/terms/

// @contact.name   API Support
// @contact.url    http://www.example.com/support
// @contact.email  support@example.com

// @license.name  MIT
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html

// @host      localhost:3000
// @BasePath  /

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize database connections
	if err := database.InitPostgres(cfg.DatabaseURL); err != nil {
		log.Fatalf("Failed to initialize PostgreSQL: %v", err)
	}
	defer database.Close()

	if err := database.InitRedis(cfg.RedisURL); err != nil {
		log.Fatalf("Failed to initialize Redis: %v", err)
	}
	defer database.CloseRedis()

	// Run SQL Migrations (Automated for Railway/Docker)
	if err := database.RunMigrations(database.DB); err != nil {
		log.Printf("⚠ Warning: SQL Migrations failed: %v", err)
		// Don't fatal, as it might be a transient issue or existing schema
	}

	// Check if tables exist before running auto-migrations
	// This avoids constraint name conflicts when tables are created via SQL migrations
	var tableExists bool
	database.DB.Raw("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')").Scan(&tableExists)

	if !tableExists {
		// Tables don't exist, run auto-migrations
		if err := database.DB.AutoMigrate(&models.User{}, &models.VerificationCode{}); err != nil {
			log.Fatalf("Failed to run migrations: %v", err)
		}
		log.Println("Database tables created successfully")
	} else {
		// Tables exist, skip auto-migration to avoid constraint conflicts
		log.Println("Database tables already exist, skipping auto-migration")
		// Still try to sync schema for new fields (non-destructive)
		if err := database.DB.AutoMigrate(&models.User{}, &models.VerificationCode{}); err != nil {
			// Log but don't fail - constraint name mismatches are OK
			log.Printf("Note: Schema sync encountered minor issues (this is normal): %v", err)
		}
	}

	// Setup Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// Middleware
	r.Use(gin.Recovery())
	r.Use(gin.Logger())

	// CORS middleware - allow all origins for mobile apps
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With", "Upgrade", "Connection"}
	config.ExposeHeaders = []string{"Content-Length"}
	config.AllowCredentials = false
	r.Use(cors.New(config))

	// Rate limiting (exclude Swagger UI, health check, and WebSocket)
	r.Use(func(c *gin.Context) {
		path := c.Request.URL.Path
		// Skip rate limiting for Swagger UI, health check, and WebSocket
		if path == "/health" ||
			path == "/swagger" ||
			path == "/swagger/" ||
			(len(path) > 9 && path[:9] == "/swagger/") ||
			path == "/api/chat/ws" { // WebSocket endpoint excluded
			c.Next()
			return
		}
		// Apply rate limiting for other routes
		auth.RateLimitMiddleware()(c)
	})

	// Swagger UI
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Health check endpoint
	// @Summary Health check
	// @Description Check if the API and database are healthy
	// @Tags health
	// @Produce json
	// @Success 200 {object} map[string]string
	// @Failure 503 {object} map[string]string
	// @Router /health [get]
	r.GET("/health", func(c *gin.Context) {
		if err := database.HealthCheck(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"error":  err.Error(),
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
		})
	})

	// Initialize auth components
	authRepo := auth.NewRepository()
	authService := auth.NewService(authRepo, cfg)
	authHandler := auth.NewHandler(authService)

	// Auth routes
	authGroup := r.Group("/api/auth")
	{
		authGroup.POST("/register", authHandler.Register)
		authGroup.POST("/login", authHandler.Login)
		authGroup.POST("/send-otp", authHandler.SendOTP)
		authGroup.POST("/verify-otp", authHandler.VerifyOTP)
		authGroup.POST("/refresh", authHandler.RefreshToken)

		// Protected routes
		protected := authGroup.Group("")
		protected.Use(auth.AuthMiddleware(cfg))
		{
			protected.POST("/logout", authHandler.Logout)
			protected.GET("/me", authHandler.GetCurrentUser)
			protected.PUT("/me", authHandler.UpdateProfile)
			protected.POST("/change-password", authHandler.ChangePassword)
		}
	}

	// Initialize listing components
	listingRepo := listing.NewRepository(database.DB)

	// Initialize R2 storage service
	var storageService listing.StorageService
	r2Storage, err := listing.NewStorageService(cfg)
	if err != nil {
		log.Printf("⚠ R2 Storage initialization failed: %v", err)
		log.Println("  Image uploads will not work until R2 is configured correctly")
		storageService = &listing.NullStorageService{}
	} else {
		storageService = r2Storage
	}

	listingService := listing.NewService(listingRepo, storageService, database.RedisClient)
	listingHandler := listing.NewHandler(listingService)

	// Listing routes
	api := r.Group("/api")
	{
		// Test route - NO AUTHENTICATION (for testing R2 upload)
		test := api.Group("/test")
		{
			test.POST("/upload", listingHandler.TestImageUpload)
		}

		cars := api.Group("/cars")

		// Public listing routes (with optional auth to detect logged-in user for isOwner/isFavorited)
		cars.GET("", auth.OptionalAuthMiddleware(cfg), listingHandler.ListListings)
		cars.GET("/:id", auth.OptionalAuthMiddleware(cfg), listingHandler.GetListing)
		cars.POST("/:id/view", listingHandler.IncrementView)

		// Protected listing routes
		protected := cars.Group("")
		protected.Use(auth.AuthMiddleware(cfg))
		{
			protected.POST("", listingHandler.CreateListing)
			protected.PUT("/:id", listingHandler.UpdateListing)
			protected.DELETE("/:id", listingHandler.DeleteListing)

			// Custom endpoints (careful with path conflicts, but these are distinct enough)
			// :id matches UUIDs usually, so "favorites" and "my-listings" might conflict if :id is catch-all.
			// Gin matches static paths first, so /cars/favorites should work before /cars/:id if :id is not regex restricted.
			// Best practice: define static paths BEFORE param paths in definition order if possible, though Gin handles it.

			// Actually, putting these inside the group might be tricky if :id is defined on the same level.
			// Let's check: /api/cars/:id vs /api/cars/my-listings
			// Gin router handles static vs param, but good to be explicit.
		}

		// Specific protected routes that shouldn't clash with :id
		// To be safe, define them before :id if they were in the same group context,
		// or relies on Gin's priority. Gin prioritizes static matches.

		protectedListings := api.Group("/cars")
		protectedListings.Use(auth.AuthMiddleware(cfg))

		protectedListings.GET("/my-listings", listingHandler.GetMyListings)
		protectedListings.GET("/favorites", listingHandler.GetFavorites)
		protectedListings.POST("/:id/favorite", listingHandler.ToggleFavorite)

		// Generic Upload Endpoint (Protected)
		api.POST("/upload", auth.AuthMiddleware(cfg), listingHandler.UploadImage)
	}

	// Initialize notification repository
	notificationRepo := notification.NewRepository(database.DB)

	// Initialize FCM client for push notifications
	var fcmClient notification.FCMService
	fcmService, err := notification.NewFCMClient(cfg)
	if err != nil {
		log.Printf("⚠ FCM service initialization failed: %v", err)
		log.Println("  Push notifications will not work until Firebase is configured")
		fcmClient = nil
	} else {
		fcmClient = fcmService
		// Set DB for device token lookups
		fcmService.SetDB(database.DB)
		log.Println("✓ FCM service initialized successfully")
	}

	// Initialize notification service (without WebSocket sender initially)
	notificationService := notification.NewService(notificationRepo, nil, fcmClient)

	// Initialize chat components
	chatRepo := chat.NewRepository(database.DB)
	chatService := chat.NewService(chatRepo, notificationService)
	chatHub := chat.NewHub(chatService)

	// Now set the WebSocket sender (chatHub) on notification service
	notificationService.SetWebSocketSender(chatHub)

	// Wire notification service to listing service for price change notifications
	listingService.SetNotificationService(notificationService)

	// Create handlers
	chatHandler := chat.NewHandler(chatHub, chatService)
	notificationHandler := notification.NewHandler(notificationService)

	// Start WebSocket Hub in background
	go chatHub.Run()

	// Register chat routes
	chatHandler.RegisterRoutes(api, auth.AuthMiddleware(cfg))

	// Register notification routes
	notificationHandler.RegisterRoutes(api, auth.AuthMiddleware(cfg))

	// Start server
	serverAddr := ":" + cfg.ServerPort
	log.Printf("Server starting on %s", serverAddr)
	if err := http.ListenAndServe(serverAddr, r); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
