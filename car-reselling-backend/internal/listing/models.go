package listing

// sda
import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

// Constants for enums
const (
	CarStatusActive  = "active"
	CarStatusSold    = "sold"
	CarStatusExpired = "expired"
	CarStatusFlagged = "flagged"
	CarStatusDeleted = "deleted"

	CarConditionExcellent = "excellent"
	CarConditionGood      = "good"
	CarConditionFair      = "fair"

	TransmissionAutomatic = "automatic"
	TransmissionManual    = "manual"

	FuelTypePetrol   = "petrol"
	FuelTypeDiesel   = "diesel"
	FuelTypeElectric = "electric"
	FuelTypeHybrid   = "hybrid"
)

// SellerInfo represents the seller details nested in a car listing
type SellerInfo struct {
	ID           uuid.UUID `json:"id" gorm:"-"`
	Name         string    `json:"name" gorm:"-"`
	ProfilePhoto string    `json:"profile_photo" gorm:"-"`
	Phone        string    `json:"phone" gorm:"-"`
}

// Car represents the car listing model in the database
type Car struct {
	ID           uuid.UUID      `json:"id" db:"id"`
	SellerID     uuid.UUID      `json:"seller_id" db:"seller_id"`
	Title        string         `json:"title" db:"title"`
	Description  string         `json:"description" db:"description"`
	Make         string         `json:"make" db:"make"`
	Model        string         `json:"model" db:"model"`
	Year         int            `json:"year" db:"year"`
	Mileage      int            `json:"mileage" db:"mileage"`
	Price        float64        `json:"price" db:"price"`
	Condition    string         `json:"condition" db:"condition"`
	Transmission string         `json:"transmission" db:"transmission"`
	FuelType     string         `json:"fuel_type" db:"fuel_type"`
	Color        string         `json:"color" db:"color"`
	VIN          string         `json:"vin" db:"vin"`
	Images       pq.StringArray `json:"images" gorm:"type:text[]" swaggertype:"array,string"`
	City         string         `json:"city" gorm:"column:city"`
	State        string         `json:"state" gorm:"column:state"`
	Latitude     float64        `json:"latitude" gorm:"-"`  // Computed from PostGIS, not stored
	Longitude    float64        `json:"longitude" gorm:"-"` // Computed from PostGIS, not stored
	Status       string         `json:"status" gorm:"column:status"`
	IsFeatured   bool           `json:"is_featured" gorm:"column:is_featured"`
	ChatOnly     bool           `json:"chat_only" gorm:"column:chat_only"`
	ViewsCount   int            `json:"views_count" gorm:"column:views_count"`
	CreatedAt    time.Time      `json:"created_at" gorm:"column:created_at"`
	UpdatedAt    time.Time      `json:"updated_at" gorm:"column:updated_at"`
	ExpiresAt    time.Time      `json:"expires_at" gorm:"column:expires_at"`

	// Joins/Extras - populated via JOIN queries, not stored in cars table
	Seller *SellerInfo `json:"seller,omitempty" gorm:"-"`
}
