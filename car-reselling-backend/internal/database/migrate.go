package database

import (
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gorm.io/gorm"
)

// RunMigrations executes all SQL migration files in the migrations directory
func RunMigrations(db *gorm.DB) error {
	log.Println("Checking for pending migrations...")

	// Directory containing migration files - in Docker this will be /app/migrations
	migrationDir := "migrations"

	// Read all files in the directory
	files, err := os.ReadDir(migrationDir)
	if err != nil {
		// Try absolute path if relative fails (fallback)
		if cwd, err := os.Getwd(); err == nil {
			log.Printf("Current working directory: %s", cwd)
			migrationDir = filepath.Join(cwd, "migrations")
			files, err = os.ReadDir(migrationDir)
		}
		
		if err != nil {
			log.Printf("Warning: Could not read migrations directory: %v", err)
			return nil // Don't crash, maybe running in environment without source
		}
	}

	// Filter for .sql files
	var migrationFiles []string
	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".sql") {
			migrationFiles = append(migrationFiles, file.Name())
		}
	}

	// Sort by name to ensure correct order (001, 002, etc.)
	sort.Strings(migrationFiles)

	for _, fileName := range migrationFiles {
		log.Printf("Executing migration: %s", fileName)
		
		content, err := os.ReadFile(filepath.Join(migrationDir, fileName))
		if err != nil {
			return err
		}

		// Split by semicolon to execute separate statements if needed, 
		// but gorm/postgres driver often handles multi-statement execution.
		// However, for safety with transactions, let's treat the whole file as one block 
		// unless we run into issues.
		// NOTE: Some drivers don't support multiple stats in one Exec.
		// But let's try standard execution first.
		
		sqlContent := string(content)

		// Create a schema_migrations table to track what ran? 
		// For this "simple automation" requested by user, we might just try to run them.
		// But running `CREATE TABLE` repeatedly fails.
		// So we need to wrap in checks or use "IF NOT EXISTS".
		// Since our SQL files (001, 002) use CREATE TABLE ...
		// We should really only run them if the tables don't exist.
		
		// Simplest Check:
		// 001 creates "users".
		// 002 creates "cars".
		// 003 alters "cars". 
		
		// Let's implement a naive check to avoid errors on repeated runs:
		if fileName == "001_create_users_table.sql" {
			if db.Migrator().HasTable("users") {
				log.Println("Skipping 001 (users table already exists)")
				continue
			}
		}
		if fileName == "002_create_listings_tables.sql" {
			if db.Migrator().HasTable("cars") {
				log.Println("Skipping 002 (cars table already exists)")
				continue
			}
		}
		if fileName == "003_make_fields_optional.sql" {
			// Check if column is nullable/changed? Hard to check.
			// Ideally we track migrations in a table.
			// Let's create a migrations table tracking.
		}

		// Better approach: Track executed migrations
		// Create migrations table if not exists
		if err := db.Exec("CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(255) PRIMARY KEY)").Error; err != nil {
			return err
		}

		// Check if already executed
		var count int64
		db.Table("schema_migrations").Where("version = ?", fileName).Count(&count)
		if count > 0 {
			log.Printf("Migration %s already executed, skipping.", fileName)
			continue
		}

		// Execute
		if err := db.Exec(sqlContent).Error; err != nil {
			return err
		}

		// Record execution
		if err := db.Exec("INSERT INTO schema_migrations (version) VALUES (?)", fileName).Error; err != nil {
			return err
		}
		
		log.Printf("Migration %s executed successfully.", fileName)
	}

	return nil
}
