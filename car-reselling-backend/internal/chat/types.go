package chat

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
)

// Metadata represents flexible JSONB data with proper Scanner/Valuer implementation
type Metadata map[string]interface{}

// Value implements driver.Valuer interface for GORM
func (m Metadata) Value() (driver.Value, error) {
	if m == nil {
		return json.Marshal(map[string]interface{}{})
	}
	return json.Marshal(m)
}

// Scan implements sql.Scanner interface for GORM
func (m *Metadata) Scan(value interface{}) error {
	if value == nil {
		*m = make(Metadata)
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("failed to unmarshal JSONB value: expected []byte")
	}

	result := make(Metadata)
	if err := json.Unmarshal(bytes, &result); err != nil {
		return err
	}

	*m = result
	return nil
}
