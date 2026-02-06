-- Add chat_only column to cars table
ALTER TABLE cars ADD COLUMN chat_only BOOLEAN DEFAULT FALSE;
