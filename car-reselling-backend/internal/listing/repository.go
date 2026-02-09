package listing

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ListingRepository interface
type ListingRepository interface {
	Create(ctx context.Context, car *Car) error
	FindByID(ctx context.Context, id uuid.UUID) (*Car, error)
	FindAll(ctx context.Context, query ListCarsQuery) ([]Car, int64, error)
	Update(ctx context.Context, car *Car) error
	Delete(ctx context.Context, id uuid.UUID) error
	FindBySellerID(ctx context.Context, sellerID uuid.UUID, page, limit int) ([]Car, int64, error)
	IncrementViews(ctx context.Context, carID uuid.UUID) error

	// Favorites
	AddToFavorites(ctx context.Context, userID, carID uuid.UUID) error
	RemoveFromFavorites(ctx context.Context, userID, carID uuid.UUID) error
	GetFavorites(ctx context.Context, userID uuid.UUID, page, limit int) ([]Car, int64, error)
	IsFavorited(ctx context.Context, userID, carID uuid.UUID) (bool, error)
	GetUsersFavoritedCar(ctx context.Context, carID uuid.UUID) ([]uuid.UUID, error)

	// Limits
	CountDailyPosts(ctx context.Context, userID uuid.UUID) (int64, error)
}

type postgresRepository struct {
	db *gorm.DB
}

// NewRepository creates a new ListingRepository
func NewRepository(db *gorm.DB) ListingRepository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) Create(ctx context.Context, car *Car) error {
	// Use raw SQL to properly handle PostgreSQL ENUM types
	// If lat/long are 0,0 (default), store NULL so map won't show
	query := `
		INSERT INTO cars (
			id, seller_id, title, description, make, model, year, mileage, price,
			condition, transmission, fuel_type, color, vin, images, city, state,
			latitude, longitude, status, is_featured, views_count, created_at, updated_at, expires_at, chat_only
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9,
			NULLIF($10, '')::car_condition,
			NULLIF($11, '')::car_transmission,
			$12::car_fuel_type,
			NULLIF($13, ''), NULLIF($14, ''), $15, $16, NULLIF($17, ''),
			CASE WHEN $18 = 0 THEN NULL ELSE $18 END,
			CASE WHEN $19 = 0 THEN NULL ELSE $19 END,
			$20::car_status, $21, $22, $23, $24, $25, $26
		)
	`
	return r.db.WithContext(ctx).Exec(query,
		car.ID, car.SellerID, car.Title, car.Description,
		car.Make, car.Model, car.Year, car.Mileage, car.Price,
		car.Condition, car.Transmission, car.FuelType, car.Color, car.VIN,
		car.Images, car.City, car.State,
		car.Latitude, car.Longitude,
		car.Status, car.IsFeatured, car.ViewsCount,
		car.CreatedAt, car.UpdatedAt, car.ExpiresAt, car.ChatOnly,
	).Error
}

func (r *postgresRepository) FindByID(ctx context.Context, id uuid.UUID) (*Car, error) {
	var result struct {
		Car
		SellerName   string  `gorm:"column:seller_name"`
		SellerPhoto  string  `gorm:"column:seller_photo"`
		SellerPhone  string  `gorm:"column:seller_phone"`
		SellerRating float64 `gorm:"column:seller_rating"`
	}

	query := `
		SELECT c.*,
			   u.full_name as seller_name,
			   u.profile_photo_url as seller_photo,
			   u.phone as seller_phone
		FROM cars c
		LEFT JOIN users u ON c.seller_id = u.id
		WHERE c.id = ? AND c.status != 'deleted'
	`
	err := r.db.WithContext(ctx).Raw(query, id.String()).Scan(&result).Error
	if err != nil {
		return nil, err
	}
	if result.Car.ID == uuid.Nil {
		return nil, gorm.ErrRecordNotFound
	}

	result.Car.Seller = &SellerInfo{
		ID:           result.Car.SellerID,
		Name:         result.SellerName,
		ProfilePhoto: result.SellerPhoto,
		Phone:        result.SellerPhone,
	}

	return &result.Car, nil
}

func (r *postgresRepository) FindAll(ctx context.Context, q ListCarsQuery) ([]Car, int64, error) {
	var cars []Car
	var total int64

	// Build base query - Note: seller_id is TEXT, users.id is UUID
	baseQuery := `
		FROM cars c
		JOIN users u ON c.seller_id = u.id
		WHERE c.status = 'active'
	`
	var args []interface{}
	var conditions []string

	if q.Make != "" {
		conditions = append(conditions, "c.make = ?")
		args = append(args, q.Make)
	}
	if q.Model != "" {
		conditions = append(conditions, "c.model = ?")
		args = append(args, q.Model)
	}
	if q.MinPrice > 0 {
		conditions = append(conditions, "c.price >= ?")
		args = append(args, q.MinPrice)
	}
	if q.MaxPrice > 0 {
		conditions = append(conditions, "c.price <= ?")
		args = append(args, q.MaxPrice)
	}
	if q.City != "" {
		conditions = append(conditions, "c.city = ?")
		args = append(args, q.City)
	}
	if q.Condition != "" {
		conditions = append(conditions, "c.condition = ?")
		args = append(args, q.Condition)
	}

	if len(conditions) > 0 {
		baseQuery += " AND " + strings.Join(conditions, " AND ")
	}

	// Count total
	countQuery := "SELECT count(*) " + baseQuery
	if err := r.db.WithContext(ctx).Raw(countQuery, args...).Scan(&total).Error; err != nil {
		return nil, 0, err
	}

	// Sorting
	order := "c.created_at DESC"
	switch q.SortBy {
	case "price_asc":
		order = "c.price ASC"
	case "price_desc":
		order = "c.price DESC"
	case "year_asc":
		order = "c.year ASC"
	case "year_desc":
		order = "c.year DESC"
	}

	// Pagination
	offset := (q.Page - 1) * q.Limit

	// Final Select - Extract lat/long from coordinates
	selectQuery := `
		SELECT c.*,
			   u.full_name as seller_name,
			   u.profile_photo_url as seller_photo,
			   u.phone as seller_phone
	` + baseQuery + fmt.Sprintf(" ORDER BY %s, c.id DESC LIMIT ? OFFSET ?", order)

	args = append(args, q.Limit, offset)

	// Use anonymous struct slice to scan
	var results []struct {
		Car
		SellerName  string `gorm:"column:seller_name"`
		SellerPhoto string `gorm:"column:seller_photo"`
		SellerPhone string `gorm:"column:seller_phone"`
	}

	if err := r.db.WithContext(ctx).Raw(selectQuery, args...).Scan(&results).Error; err != nil {
		return nil, 0, err
	}

	// Map back to []Car
	cars = make([]Car, len(results))
	for i, res := range results {
		cars[i] = res.Car
		cars[i].Seller = &SellerInfo{
			ID:           res.Car.SellerID,
			Name:         res.SellerName,
			ProfilePhoto: res.SellerPhoto,
			Phone:        res.SellerPhone,
		}
	}

	return cars, total, nil
}

func (r *postgresRepository) Update(ctx context.Context, car *Car) error {
	return r.db.WithContext(ctx).Save(car).Error
}

func (r *postgresRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// Soft delete
	return r.db.WithContext(ctx).Exec("UPDATE cars SET status = 'deleted' WHERE id = ?", id.String()).Error
}

func (r *postgresRepository) FindBySellerID(ctx context.Context, sellerID uuid.UUID, page, limit int) ([]Car, int64, error) {
	var cars []Car
	var total int64
	offset := (page - 1) * limit

	if err := r.db.WithContext(ctx).Model(&Car{}).Where("seller_id = ? AND status != 'deleted'", sellerID.String()).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	query := `
		SELECT c.*
		FROM cars c
		WHERE c.seller_id = ? AND c.status != 'deleted'
		ORDER BY c.created_at DESC
		LIMIT ? OFFSET ?
	`
	err := r.db.WithContext(ctx).Raw(query, sellerID.String(), limit, offset).Scan(&cars).Error
	return cars, total, err
}

func (r *postgresRepository) IncrementViews(ctx context.Context, carID uuid.UUID) error {
	return r.db.WithContext(ctx).Exec("UPDATE cars SET views_count = views_count + 1 WHERE id = ?", carID.String()).Error
}

func (r *postgresRepository) AddToFavorites(ctx context.Context, userID, carID uuid.UUID) error {
	query := "INSERT INTO favorites (user_id, car_id) VALUES (?, ?) ON CONFLICT DO NOTHING"
	return r.db.WithContext(ctx).Exec(query, userID.String(), carID.String()).Error
}

func (r *postgresRepository) RemoveFromFavorites(ctx context.Context, userID, carID uuid.UUID) error {
	return r.db.WithContext(ctx).Exec("DELETE FROM favorites WHERE user_id = ? AND car_id = ?", userID.String(), carID.String()).Error
}

func (r *postgresRepository) GetFavorites(ctx context.Context, userID uuid.UUID, page, limit int) ([]Car, int64, error) {
	var cars []Car
	var total int64
	offset := (page - 1) * limit

	// Count
	r.db.WithContext(ctx).Table("favorites").Where("user_id = ?", userID.String()).Count(&total)

	query := `
		SELECT c.*,
			   u.full_name as seller_name,
			   u.profile_photo_url as seller_photo,
			   u.phone as seller_phone
		FROM favorites f
		JOIN cars c ON f.car_id = c.id
		LEFT JOIN users u ON c.seller_id = u.id
		WHERE f.user_id = ?
		ORDER BY f.created_at DESC
		LIMIT ? OFFSET ?
	`
	err := r.db.WithContext(ctx).Raw(query, userID.String(), limit, offset).Scan(&cars).Error
	return cars, total, err
}

func (r *postgresRepository) IsFavorited(ctx context.Context, userID, carID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Table("favorites").Where("user_id = ? AND car_id = ?", userID.String(), carID.String()).Count(&count).Error
	return count > 0, err
}

func (r *postgresRepository) CountDailyPosts(ctx context.Context, userID uuid.UUID) (int64, error) {
	var count int64
	// PostgreSQL's CURRENT_DATE or we can pass explicit time.
	// To be safe with timezones, let's assume we want "last 24 hours" OR "since midnight UTC".
	// Requirement says "reset at midnight". simpler to use database logic:
	// WHERE created_at >= current_date

	err := r.db.WithContext(ctx).Model(&Car{}).
		Where("seller_id = ? AND created_at >= CURRENT_DATE", userID.String()).
		Count(&count).Error
	return count, err
}

func (r *postgresRepository) GetUsersFavoritedCar(ctx context.Context, carID uuid.UUID) ([]uuid.UUID, error) {
	var userIDStrings []string
	err := r.db.WithContext(ctx).
		Table("favorites").
		Where("car_id = ?", carID.String()).
		Pluck("user_id", &userIDStrings).Error
	if err != nil {
		return nil, err
	}

	// Convert strings to UUIDs
	userIDs := make([]uuid.UUID, 0, len(userIDStrings))
	for _, idStr := range userIDStrings {
		id, err := uuid.Parse(idStr)
		if err != nil {
			continue // Skip invalid UUIDs
		}
		userIDs = append(userIDs, id)
	}
	return userIDs, nil
}
