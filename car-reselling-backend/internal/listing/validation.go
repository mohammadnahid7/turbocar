package listing

import (
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"
)

// ValidateCreateCarRequest performs custom validation for creating a car
func ValidateCreateCarRequest(req CreateCarRequest) error {
	// Most validation is handled by struct tags (binding:"required,...")
	// This function is for complex validation logic

	currentYear := time.Now().Year()
	if req.Year > currentYear+1 {
		return fmt.Errorf("year cannot be in the future (max %d)", currentYear+1)
	}

	return nil
}

// ValidateUpdateCarRequest performs custom validation for updating a car
func ValidateUpdateCarRequest(req UpdateCarRequest) error {
	currentYear := time.Now().Year()
	if req.Year != 0 && req.Year > currentYear+1 {
		return fmt.Errorf("year cannot be in the future (max %d)", currentYear+1)
	}
	return nil
}

// ValidateImages checks file count, size, and type
func ValidateImages(files []*multipart.FileHeader) error {
	if len(files) < 1 {
		return fmt.Errorf("at least 1 image is required")
	}
	if len(files) > 10 {
		return fmt.Errorf("maximum 10 images allowed")
	}

	for _, file := range files {
		// Maxwell size 10MB
		if file.Size > 10*1024*1024 {
			return fmt.Errorf("image %s exceeds 10MB limit", file.Filename)
		}

		// Check extension
		ext := strings.ToLower(filepath.Ext(file.Filename))
		if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
			return fmt.Errorf("image %s has invalid type (allowed: jpg, jpeg, png)", file.Filename)
		}
	}
	return nil
}

// IsValidCarStatus checks if the status is valid
func IsValidCarStatus(status string) bool {
	switch status {
	case CarStatusActive, CarStatusSold, CarStatusExpired, CarStatusFlagged, CarStatusDeleted:
		return true
	}
	return false
}

// IsValidCondition checks if the condition is valid
func IsValidCondition(condition string) bool {
	switch condition {
	case CarConditionExcellent, CarConditionGood, CarConditionFair:
		return true
	}
	return false
}

// IsValidFuelType checks if the fuel type is valid
func IsValidFuelType(fuelType string) bool {
	switch fuelType {
	case FuelTypePetrol, FuelTypeDiesel, FuelTypeElectric, FuelTypeHybrid:
		return true
	}
	return false
}
