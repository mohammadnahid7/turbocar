package listing

import (
	"mime/multipart"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ListingHandler struct
type ListingHandler struct {
	service *ListingService
}

// NewHandler creates a new ListingHandler
func NewHandler(service *ListingService) *ListingHandler {
	return &ListingHandler{service: service}
}

// CreateListing handles creating a new listing
// @Summary Create a new car listing
// @Description Create a new car listing with images
// @Tags listings
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param title formData string true "Car Title"
// @Param description formData string true "Description"
// @Param make formData string true "Make (e.g. Toyota)"
// @Param model formData string true "Model (e.g. Camry)"
// @Param year formData int true "Year"
// @Param mileage formData int true "Mileage"
// @Param price formData number true "Price"
// @Param condition formData string true "Condition"
// @Param transmission formData string true "Transmission"
// @Param fuel_type formData string true "Fuel Type"
// @Param color formData string true "Color"
// @Param vin formData string false "VIN"
// @Param city formData string true "City"
// @Param state formData string true "State"
// @Param latitude formData number true "Latitude"
// @Param longitude formData number true "Longitude"
// @Param images formData file true "Car Images"
// @Success 201 {object} Car
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/cars [post]
func (h *ListingHandler) CreateListing(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	var req CreateCarRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse multipart form"})
		return
	}

	files := form.File["images"]
	// Allow posting without images temporarily (will use dummy images)
	// Later when cloud storage is ready, uncomment this:
	// if len(files) == 0 {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": "At least 1 image is required"})
	// 	return
	// }

	car, err := h.service.CreateListing(c.Request.Context(), userID, req, files)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, car)
}

// GetListing handles getting a single listing
// @Summary Get a car listing
// @Description Get detailed information about a car listing
// @Tags listings
// @Accept json
// @Produce json
// @Param id path string true "Car ID"
// @Success 200 {object} CarResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /api/cars/{id} [get]
func (h *ListingHandler) GetListing(c *gin.Context) {
	idStr := c.Param("id")
	carID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid car ID"})
		return
	}

	var userID uuid.UUID
	if val, exists := c.Get("userID"); exists {
		if id, ok := val.(string); ok {
			userID, _ = uuid.Parse(id)
		}
	}

	car, err := h.service.GetListing(c.Request.Context(), carID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Listing not found"})
		return
	}

	c.JSON(http.StatusOK, car)
}

// ListListings handles searching and filtering listings
// @Summary List car listings
// @Description Search and filter car listings
// @Tags listings
// @Accept json
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Param make query string false "Make"
// @Param model query string false "Model"
// @Param min_price query number false "Min Price"
// @Param max_price query number false "Max Price"
// @Param city query string false "City"
// @Param state query string false "State"
// @Param condition query string false "Condition"
// @Param sort_by query string false "Sort By"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Router /api/cars [get]
func (h *ListingHandler) ListListings(c *gin.Context) {
	var query ListCarsQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if query.Limit == 0 {
		query.Limit = 20
	}
	if query.Page == 0 {
		query.Page = 1
	}

	var userID uuid.UUID
	if val, exists := c.Get("userID"); exists {
		if id, ok := val.(string); ok {
			userID, _ = uuid.Parse(id)
		}
	}

	cars, total, err := h.service.ListListings(c.Request.Context(), query, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":     cars,
		"total":    total,
		"page":     query.Page,
		"limit":    query.Limit,
		"has_more": total > int64(query.Page*query.Limit),
	})
}

// UpdateListing handles updating a listing
// @Summary Update a car listing
// @Description Update an existing car listing details and images
// @Tags listings
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param id path string true "Car ID"
// @Param title formData string false "Car Title"
// @Param description formData string false "Description"
// @Param price formData number false "Price"
// @Param images formData file false "New Images"
// @Success 200 {object} Car
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/cars/{id} [put]
func (h *ListingHandler) UpdateListing(c *gin.Context) {
	idStr := c.Param("id")
	carID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid car ID"})
		return
	}

	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	var req UpdateCarRequest
	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var files []*multipart.FileHeader
	form, err := c.MultipartForm()
	if err == nil {
		files = form.File["images"]
	}

	car, err := h.service.UpdateListing(c.Request.Context(), carID, userID, req, files)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, car)
}

// DeleteListing handles deleting a listing
// @Summary Delete a car listing
// @Description Soft delete a car listing
// @Tags listings
// @Security BearerAuth
// @Produce json
// @Param id path string true "Car ID"
// @Success 204 "No Content"
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/cars/{id} [delete]
func (h *ListingHandler) DeleteListing(c *gin.Context) {
	idStr := c.Param("id")
	carID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid car ID"})
		return
	}

	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	if err := h.service.DeleteListing(c.Request.Context(), carID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// GetMyListings handles getting current user's listings
// @Summary Get my listings
// @Description Get detailed information about the authenticated user's car listings
// @Tags listings
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Router /api/cars/my-listings [get]
func (h *ListingHandler) GetMyListings(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	cars, total, err := h.service.GetMyListings(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  cars,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// ToggleFavorite handles toggling favorite status
// @Summary Toggle favorite status
// @Description Add or remove a car from favorites
// @Tags listings
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Car ID"
// @Success 200 {object} map[string]bool
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /api/cars/{id}/favorite [post]
func (h *ListingHandler) ToggleFavorite(c *gin.Context) {
	idStr := c.Param("id")
	carID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid car ID"})
		return
	}

	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	favorited, err := h.service.ToggleFavorite(c.Request.Context(), userID, carID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"favorited": favorited})
}

// GetFavorites handles getting current user's favorites
// @Summary Get my favorites
// @Description Get the authenticated user's favorite car listings
// @Tags listings
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Router /api/cars/favorites [get]
func (h *ListingHandler) GetFavorites(c *gin.Context) {
	userIDStr := c.GetString("userID")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	cars, total, err := h.service.GetFavorites(c.Request.Context(), userID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  cars,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// TestImageUpload handles testing image upload to R2 without authentication
// @Summary Test image upload to R2
// @Description Upload a test image to Cloudflare R2 (no auth required - for testing only)
// @Tags test
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "Image file to upload"
// @Success 200 {object} map[string]interface{} "Returns uploaded image URL"
// @Failure 400 {object} map[string]string "Bad request"
// @Failure 500 {object} map[string]string "Server error"
// @Router /api/test/upload [post]
func (h *ListingHandler) TestImageUpload(c *gin.Context) {
	// Get the file from form
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "No image file provided",
			"details": err.Error(),
		})
		return
	}

	// Validate file size (max 10MB)
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "File too large (max 10MB)",
			"size":  file.Size,
		})
		return
	}

	// Upload using storage service
	files := []*multipart.FileHeader{file}
	testID := "test-" + uuid.New().String()[:8]

	urls, err := h.service.storage.UploadMultipleImages(c.Request.Context(), files, testID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to upload image",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"message":  "Image uploaded successfully!",
		"url":      urls[0],
		"filename": file.Filename,
		"size":     file.Size,
		"test_id":  testID,
	})
}

// IncrementView handles incrementing view count
// @Summary Increment view count
// @Description Increment the view count for a car listing
// @Tags listings
// @Produce json
// @Param id path string true "Car ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Router /api/cars/{id}/view [post]
func (h *ListingHandler) IncrementView(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid car ID"})
		return
	}

	h.service.incrementViewCount(c.Request.Context(), id)

	c.JSON(http.StatusOK, gin.H{"message": "View incremented"})
}

// UploadImage handles image upload for authenticated users
// @Summary Upload an image
// @Description Upload an image to Cloudflare R2
// @Tags common
// @Security BearerAuth
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "Image file to upload"
// @Success 200 {object} map[string]interface{} "Returns uploaded image URL"
// @Failure 400 {object} map[string]string "Bad request"
// @Failure 401 {object} map[string]string "Unauthorized"
// @Failure 500 {object} map[string]string "Server error"
// @Router /api/upload [post]
func (h *ListingHandler) UploadImage(c *gin.Context) {
	// Verify auth
	userIDStr := c.GetString("userID")
	if userIDStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Get the file from form
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "No image file provided",
			"details": err.Error(),
		})
		return
	}

	// Validate file size (max 10MB)
	if file.Size > 10*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "File too large (max 10MB)",
			"size":  file.Size,
		})
		return
	}

	// Upload using storage service
	files := []*multipart.FileHeader{file}
	folder := "uploads"

	urls, err := h.service.storage.UploadMultipleImages(c.Request.Context(), files, folder)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to upload image",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"message":  "Image uploaded successfully!",
		"url":      urls[0],
		"filename": file.Filename,
	})
}
