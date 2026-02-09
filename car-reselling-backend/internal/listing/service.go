package listing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"mime/multipart"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

// NotifierService is an interface for sending push notifications
type NotifierService interface {
	SendToUsers(userIDs []uuid.UUID, title, body string, data map[string]string) error
}

// ListingService struct
type ListingService struct {
	repo     ListingRepository
	storage  StorageService
	cache    *redis.Client
	notifier NotifierService
}

// NewService creates a new ListingService
func NewService(repo ListingRepository, storage StorageService, cache *redis.Client) *ListingService {
	return &ListingService{
		repo:    repo,
		storage: storage,
		cache:   cache,
	}
}

// SetNotifier sets the notification service
func (s *ListingService) SetNotifier(n NotifierService) {
	s.notifier = n
}

// CreateListing handles creating a new car listing
func (s *ListingService) CreateListing(ctx context.Context, userID uuid.UUID, req CreateCarRequest, files []*multipart.FileHeader) (*Car, error) {
	// 1. Validate request
	if err := ValidateCreateCarRequest(req); err != nil {
		return nil, err
	}

	// 2. Check daily rate limit (5 posts per day)
	if err := s.checkRateLimit(ctx, userID); err != nil {
		return nil, err
	}

	// 3. Generate car ID first (needed for image paths)
	newCarID := uuid.New()

	// 4. Handle images - validate and upload to S3/R2
	var imageURLs pq.StringArray

	if len(files) > 0 {
		// Validate images (count, size, type)
		if err := ValidateImages(files); err != nil {
			return nil, err
		}

		// Upload to S3/R2 storage
		urls, err := s.storage.UploadMultipleImages(ctx, files, newCarID.String())
		if err != nil {
			return nil, fmt.Errorf("failed to upload images: %v", err)
		}
		imageURLs = urls
	} else {
		return nil, fmt.Errorf("at least 1 image is required")
	}

	// 5. Create car object
	now := time.Now()
	car := &Car{
		ID:           newCarID,
		SellerID:     userID,
		Title:        req.Title,
		Description:  req.Description,
		Make:         req.Make,
		Model:        req.Model,
		Year:         req.Year,
		Mileage:      req.Mileage,
		Price:        req.Price,
		Condition:    req.Condition,
		Transmission: req.Transmission,
		FuelType:     req.FuelType,
		Color:        req.Color,
		VIN:          req.VIN,
		Images:       imageURLs,
		City:         req.City,
		State:        req.State,
		Latitude:     req.Latitude,
		Longitude:    req.Longitude,
		Status:       CarStatusActive,
		ChatOnly:     req.ChatOnly,
		CreatedAt:    now,
		UpdatedAt:    now,
		ExpiresAt:    now.AddDate(0, 0, 90), // 90 days expiry
	}

	// 5. Save to DB
	if err := s.repo.Create(ctx, car); err != nil {
		return nil, err
	}

	return car, nil
}

// GetListing retrieves a car by ID
func (s *ListingService) GetListing(ctx context.Context, carID uuid.UUID, userID uuid.UUID) (*CarResponse, error) {
	cacheKey := fmt.Sprintf("cache:car:%s", carID)

	// 1. Try cache
	val, err := s.cache.Get(ctx, cacheKey).Result()
	if err == nil {
		var resp CarResponse
		if err := json.Unmarshal([]byte(val), &resp); err == nil {
			// Increment view async
			go s.incrementViewCount(context.Background(), carID)

			// If user is logged in, check isFavorited and isOwner (cache doesn't know user context)
			if userID != uuid.Nil {
				isFav, _ := s.repo.IsFavorited(ctx, userID, carID)
				resp.IsFavorited = isFav
				resp.IsOwner = (resp.SellerID == userID)
			}
			return &resp, nil
		}
	}

	// 2. Fetch from DB
	car, err := s.repo.FindByID(ctx, carID)
	if err != nil {
		return nil, err
	}

	// 3. Increment views
	go s.incrementViewCount(context.Background(), carID)

	// 4. Prepare response
	resp := &CarResponse{
		Car: *car,
	}

	if userID != uuid.Nil {
		isFav, err := s.repo.IsFavorited(ctx, userID, carID)
		if err == nil {
			resp.IsFavorited = isFav
		}
		resp.IsOwner = (car.SellerID == userID)
	}

	// 5. Cache result (base car data only really, but here we cache the struct.
	// Ideally we cache only the car data and overlay user-specifics.
	// For simplicity, we cache the object but re-check user flags if needed.
	// Actually, caching the Response with zeroed isFavorited/IsOwner is better.)

	// Reset user specific flags before caching
	cacheResp := *resp
	cacheResp.IsFavorited = false
	cacheResp.IsOwner = false

	data, _ := json.Marshal(cacheResp)
	s.cache.Set(ctx, cacheKey, data, 5*time.Minute)

	return resp, nil
}

// ListListings retrieves a list of cars
func (s *ListingService) ListListings(ctx context.Context, query ListCarsQuery, userID uuid.UUID) ([]CarResponse, int64, error) {
	// TODO: Cache list results based on query hash? (Maybe overkill for now)

	cars, total, err := s.repo.FindAll(ctx, query)
	if err != nil {
		return nil, 0, err
	}

	// Batch check favorites if user is logged in
	// Optimization: Get all favorite IDs for this user

	var responses []CarResponse
	for _, car := range cars {
		resp := CarResponse{Car: car}
		if userID != uuid.Nil {
			// N+1 query here, but optimized in repo could be better.
			// For 20 items it's acceptable, or implement repo.GetFavoriteIDs(userID) and map locally.
			// Keeping it simple as per instructions "For each car, check if favorited".
			isFav, _ := s.repo.IsFavorited(ctx, userID, car.ID)
			resp.IsFavorited = isFav
			resp.IsOwner = (car.SellerID == userID)
		}
		responses = append(responses, resp)
	}

	return responses, total, nil
}

// UpdateListing updates an existing listing
func (s *ListingService) UpdateListing(ctx context.Context, carID, userID uuid.UUID, req UpdateCarRequest, newFiles []*multipart.FileHeader) (*Car, error) {
	// 1. Fetch existing
	car, err := s.repo.FindByID(ctx, carID)
	if err != nil {
		return nil, err
	}

	// 2. Verify ownerships
	if car.SellerID != userID {
		return nil, errors.New("unauthorized: you do not own this listing")
	}

	// Track old price for notification
	oldPrice := car.Price

	// 3. Update fields
	if req.Title != "" {
		car.Title = req.Title
	}
	if req.Description != "" {
		car.Description = req.Description
	}
	if req.Make != "" {
		car.Make = req.Make
	}
	if req.Model != "" {
		car.Model = req.Model
	}
	if req.Year != 0 {
		car.Year = req.Year
	}
	if req.Mileage != 0 {
		car.Mileage = req.Mileage
	}
	if req.Price != 0 {
		car.Price = req.Price
	}
	if req.Condition != "" {
		car.Condition = req.Condition
	}
	if req.Transmission != "" {
		car.Transmission = req.Transmission
	}
	if req.FuelType != "" {
		car.FuelType = req.FuelType
	}
	if req.Color != "" {
		car.Color = req.Color
	}
	if req.City != "" {
		car.City = req.City
	}
	if req.State != "" {
		car.State = req.State
	}
	if req.Latitude != 0 {
		car.Latitude = req.Latitude
	}
	if req.Longitude != 0 {
		car.Longitude = req.Longitude
	}
	if req.Status != "" {
		car.Status = req.Status
	}

	// 4. Handle images - merge existing with new uploads
	// Start with existing images that the user wants to keep
	var finalImages []string
	if len(req.ExistingImages) > 0 {
		finalImages = append(finalImages, req.ExistingImages...)
	}

	// Upload and add new images
	if len(newFiles) > 0 {
		if err := ValidateImages(newFiles); err != nil {
			return nil, err
		}
		// Upload new images
		newUrls, err := s.storage.UploadMultipleImages(ctx, newFiles, car.ID.String())
		if err != nil {
			return nil, err
		}
		finalImages = append(finalImages, newUrls...)
	}

	// Update images only if we have some (existing or new)
	// If no existing images specified and no new files, keep original images
	if len(req.ExistingImages) > 0 || len(newFiles) > 0 {
		car.Images = finalImages
	}

	car.UpdatedAt = time.Now()

	// 5. Save
	if err := s.repo.Update(ctx, car); err != nil {
		return nil, err
	}

	// 6. Invalidate cache
	s.cache.Del(ctx, fmt.Sprintf("cache:car:%s", carID))

	// 7. Send price change notifications (async, don't block response)
	log.Printf("DEBUG: UpdateListing - notifier=%v, reqPrice=%v, oldPrice=%v, newPrice=%v",
		s.notifier != nil, req.Price, oldPrice, car.Price)
	if s.notifier != nil && oldPrice != car.Price {
		log.Printf("DEBUG: Triggering price change notification for car %s", carID)

		var carImage string
		if len(car.Images) > 0 {
			carImage = car.Images[0]
		}

		go s.sendPriceChangeNotifications(carID, car.SellerID, car.Title, oldPrice, car.Price, carImage)
	}

	return car, nil
}

// sendPriceChangeNotifications notifies users who favorited this car about price change
func (s *ListingService) sendPriceChangeNotifications(carID, ownerID uuid.UUID, carTitle string, oldPrice, newPrice float64, carImage string) {
	ctx := context.Background()

	// Get users who favorited this car
	userIDs, err := s.repo.GetUsersFavoritedCar(ctx, carID)
	if err != nil {
		log.Printf("Failed to get favorited users for car %s: %v", carID, err)
		return
	}

	if len(userIDs) == 0 {
		return
	}

	// Filter out owner and verify favorites
	var validUserIDs []uuid.UUID
	for _, uid := range userIDs {
		// Bug 1 Fix: Exclude owner
		if uid == ownerID {
			continue
		}

		// Bug 3 Fix: Verify favorite still exists (handle race conditions)
		isFav, err := s.repo.IsFavorited(ctx, uid, carID)
		if err == nil && isFav {
			validUserIDs = append(validUserIDs, uid)
		}
	}

	if len(validUserIDs) == 0 {
		return
	}

	// Determine if price went up or down
	var direction string
	if newPrice < oldPrice {
		direction = "dropped"
	} else {
		direction = "increased"
	}

	title := "Price Alert! 🔔"
	body := fmt.Sprintf("A car you saved has %s! %s: $%.0f → $%.0f", direction, carTitle, oldPrice, newPrice)

	data := map[string]string{
		"type":         "price_change",
		"car_id":       carID.String(),
		"old_price":    fmt.Sprintf("%.0f", oldPrice),
		"new_price":    fmt.Sprintf("%.0f", newPrice),
		"car_image":    carImage,
		"click_action": "FLUTTER_NOTIFICATION_CLICK",
	}

	if err := s.notifier.SendToUsers(validUserIDs, title, body, data); err != nil {
		log.Printf("Failed to send price change notifications: %v", err)
	} else {
		log.Printf("Sent price change notifications to %d users for car %s", len(validUserIDs), carID)
	}
}

// DeleteListing deletes a listing
func (s *ListingService) DeleteListing(ctx context.Context, carID, userID uuid.UUID) error {
	car, err := s.repo.FindByID(ctx, carID)
	if err != nil {
		return err
	}

	if car.SellerID != userID {
		return errors.New("unauthorized")
	}

	// Soft delete in DB
	if err := s.repo.Delete(ctx, carID); err != nil {
		return err
	}

	// Delete images?
	// Soft delete usually keeps data. But instructions say "Delete images from storage".
	// "Soft delete (set status = 'deleted') ... Delete images from storage".
	// Okay.
	go s.storage.DeleteMultipleImages(context.Background(), car.Images)

	s.cache.Del(ctx, fmt.Sprintf("cache:car:%s", carID))
	return nil
}

// GetMyListings gets user's listings
func (s *ListingService) GetMyListings(ctx context.Context, userID uuid.UUID, page, limit int) ([]Car, int64, error) {
	return s.repo.FindBySellerID(ctx, userID, page, limit)
}

// ToggleFavorite adds or removes favorite
func (s *ListingService) ToggleFavorite(ctx context.Context, userID, carID uuid.UUID) (bool, error) {
	isFav, err := s.repo.IsFavorited(ctx, userID, carID)
	if err != nil {
		return false, err
	}

	if isFav {
		err = s.repo.RemoveFromFavorites(ctx, userID, carID)
		return false, err
	}

	err = s.repo.AddToFavorites(ctx, userID, carID)
	return true, err
}

// GetFavorites gets user's favorites
func (s *ListingService) GetFavorites(ctx context.Context, userID uuid.UUID, page, limit int) ([]Car, int64, error) {
	return s.repo.GetFavorites(ctx, userID, page, limit)
}

// Helpers

func (s *ListingService) checkRateLimit(ctx context.Context, userID uuid.UUID) error {
	// Check against database count for today
	count, err := s.repo.CountDailyPosts(ctx, userID)
	if err != nil {
		return err
	}

	if count >= 5 {
		return errors.New("daily post limit reached: max 5 listings per day")
	}
	return nil
}

func (s *ListingService) incrementViewCount(ctx context.Context, carID uuid.UUID) {
	key := fmt.Sprintf("views:car:%s", carID)
	// Increment Redis counter
	// Flush strategy: Increment redis. If % 100 == 0, flush to DB.
	// Or just blindly increment DB? "Increment views... (async or batch)"
	// To be safe and persistent, incrementing DB directly (async) is easiest for now.
	// But optimizing:

	val, err := s.cache.Incr(ctx, key).Result()
	if err != nil {
		return
	}

	// Flush every 10 views to DB
	if val%10 == 0 {
		s.repo.IncrementViews(ctx, carID)
	}
}
