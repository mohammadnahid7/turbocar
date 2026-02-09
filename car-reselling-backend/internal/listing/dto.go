package listing

// CreateCarRequest represents the payload for creating a listing
// @Description Request payload for creating a new car listing
type CreateCarRequest struct {
	Title        string  `form:"title" binding:"required,min=10,max=100" example:"Toyota Camry 2020"`
	Description  string  `form:"description" binding:"required,min=20" example:"Well maintained car, single owner..."`
	Make         string  `form:"make" binding:"required" example:"Toyota"`
	Model        string  `form:"model" binding:"required" example:"Camry"`
	Year         int     `form:"year" binding:"required,min=1900" example:"2020"`
	Mileage      int     `form:"mileage" binding:"required,min=0" example:"15000"`
	Price        float64 `form:"price" binding:"required,gt=0" example:"25000"`
	Condition    string  `form:"condition" binding:"omitempty,oneof=excellent good fair" example:"excellent"`
	Transmission string  `form:"transmission" binding:"omitempty,oneof=automatic manual" example:"automatic"`
	FuelType     string  `form:"fuel_type" binding:"required,oneof=petrol diesel electric hybrid" example:"petrol"`
	Color        string  `form:"color" binding:"omitempty" example:"White"`
	VIN          string  `form:"vin" binding:"omitempty,alphanum" example:"ABC1234567890"`
	City         string  `form:"city" binding:"required" example:"New York"`
	State        string  `form:"state" binding:"omitempty" example:"NY"`
	Latitude     float64 `form:"latitude" binding:"omitempty" example:"40.7128"`
	Longitude    float64 `form:"longitude" binding:"omitempty" example:"-74.0060"`
	ChatOnly     bool    `form:"chat_only" example:"true"`
}

// UpdateCarRequest represents the payload for updating a listing
// @Description Request payload for updating an existing car listing
type UpdateCarRequest struct {
	Title          string   `form:"title" binding:"omitempty,min=10,max=100" example:"Toyota Camry 2020 Updated"`
	Description    string   `form:"description" binding:"omitempty,min=20" example:"Updated description..."`
	Make           string   `form:"make" binding:"omitempty" example:"Toyota"`
	Model          string   `form:"model" binding:"omitempty" example:"Camry"`
	Year           int      `form:"year" binding:"omitempty,min=1900" example:"2020"`
	Mileage        int      `form:"mileage" binding:"omitempty,min=0" example:"16000"`
	Price          float64  `form:"price" binding:"omitempty,gt=0" example:"24000"`
	Condition      string   `form:"condition" binding:"omitempty,oneof=excellent good fair" example:"good"`
	Transmission   string   `form:"transmission" binding:"omitempty,oneof=automatic manual" example:"automatic"`
	FuelType       string   `form:"fuel_type" binding:"omitempty,oneof=petrol diesel electric hybrid" example:"petrol"`
	Color          string   `form:"color" binding:"omitempty" example:"Silver"`
	VIN            string   `form:"vin" binding:"omitempty,alphanum" example:"ABC1234567890"`
	City           string   `form:"city" binding:"omitempty" example:"Albany"`
	State          string   `form:"state" binding:"omitempty" example:"NY"`
	Latitude       float64  `form:"latitude" binding:"omitempty,latitude" example:"42.6526"`
	Longitude      float64  `form:"longitude" binding:"omitempty,longitude" example:"-73.7562"`
	Status         string   `form:"status" binding:"omitempty,oneof=active sold expired deleted" example:"active"`
	ChatOnly       bool     `form:"chat_only" example:"false"`
	ExistingImages []string `form:"existing_images" binding:"omitempty"`
}

// ListCarsQuery represents the query parameters for listing cars
// @Description Query parameters for filtering and searching cars
type ListCarsQuery struct {
	Page      int     `form:"page,default=1" binding:"min=1" example:"1"`
	Limit     int     `form:"limit,default=20" binding:"min=1,max=100" example:"20"`
	Make      string  `form:"make" example:"Toyota"`
	Model     string  `form:"model" example:"Camry"`
	MinPrice  float64 `form:"min_price" binding:"omitempty,min=0" example:"10000"`
	MaxPrice  float64 `form:"max_price" binding:"omitempty,gtefield=MinPrice" example:"50000"`
	City      string  `form:"city" example:"New York"`
	State     string  `form:"state" example:"NY"`
	Condition string  `form:"condition" example:"excellent"`
	SortBy    string  `form:"sort_by,default=created_at_desc" binding:"oneof=created_at_desc price_asc price_desc year_desc year_asc" example:"created_at_desc"`
}

// CarResponse represents the API response for a car
// @Description Detailed car information response
type CarResponse struct {
	Car
	IsFavorited bool `json:"is_favorited" example:"false"`
	IsOwner     bool `json:"is_owner" example:"true"`
}
