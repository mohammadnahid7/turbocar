-- Migration to make optional fields nullable
-- This allows posting cars without condition, transmission, color, state, latitude, longitude

-- Make condition column nullable (remove NOT NULL constraint)
ALTER TABLE cars ALTER COLUMN condition DROP NOT NULL;

-- Make transmission column nullable (remove NOT NULL constraint)
ALTER TABLE cars ALTER COLUMN transmission DROP NOT NULL;

-- Make state column nullable (remove NOT NULL constraint)
ALTER TABLE cars ALTER COLUMN state DROP NOT NULL;

-- Note: color, coordinates (lat/long) are already nullable in the original schema
