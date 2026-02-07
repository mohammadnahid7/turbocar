-- Migration: Add car context to conversations
-- UP Migration

-- Add car context columns for marketplace chat
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS car_id UUID;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS car_title VARCHAR(255);
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS car_seller_id UUID;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMP WITH TIME ZONE;

-- Add indexes for car context queries
CREATE INDEX IF NOT EXISTS idx_conversations_car_id ON conversations(car_id);
CREATE INDEX IF NOT EXISTS idx_conversations_car_seller_id ON conversations(car_seller_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON conversations(last_message_at DESC);

-- Add foreign key constraint for car_id (optional, depends on cars table existence)
-- ALTER TABLE conversations ADD CONSTRAINT fk_conversations_car FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE SET NULL;

-- DOWN Migration
-- DROP INDEX IF EXISTS idx_conversations_last_message_at;
-- DROP INDEX IF EXISTS idx_conversations_car_seller_id;
-- DROP INDEX IF EXISTS idx_conversations_car_id;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS last_message_at;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS car_seller_id;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS car_title;
-- ALTER TABLE conversations DROP COLUMN IF EXISTS car_id;
