-- Create listings tables (Railway-compatible version)

-- Create ENUM types (use DO block to avoid errors if they exist)
DO $$ BEGIN
    CREATE TYPE car_status AS ENUM ('active', 'sold', 'expired', 'flagged', 'deleted');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE car_condition AS ENUM ('excellent', 'good', 'fair');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE car_transmission AS ENUM ('automatic', 'manual');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE car_fuel_type AS ENUM ('petrol', 'diesel', 'electric', 'hybrid');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create cars table (using simple lat/lng instead of PostGIS GEOMETRY)
CREATE TABLE IF NOT EXISTS cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    mileage INT NOT NULL CHECK (mileage >= 0),
    price DECIMAL(12, 2) NOT NULL CHECK (price > 0),
    condition car_condition,
    transmission car_transmission,
    fuel_type car_fuel_type NOT NULL,
    color VARCHAR(30),
    vin VARCHAR(17),
    images TEXT[] DEFAULT '{}',
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status car_status NOT NULL DEFAULT 'active',
    is_featured BOOLEAN DEFAULT FALSE,
    views_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cars_seller ON cars(seller_id);
CREATE INDEX IF NOT EXISTS idx_cars_status ON cars(status);
CREATE INDEX IF NOT EXISTS idx_cars_price ON cars(price);
CREATE INDEX IF NOT EXISTS idx_cars_created_at ON cars(created_at);
CREATE INDEX IF NOT EXISTS idx_cars_make_model ON cars(make, model);
CREATE INDEX IF NOT EXISTS idx_cars_year ON cars(year);
-- Simple index for lat/lng queries
CREATE INDEX IF NOT EXISTS idx_cars_location ON cars(latitude, longitude);

-- Create favorites table
CREATE TABLE IF NOT EXISTS favorites (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, car_id)
);

-- Create car_views table for analytics
CREATE TABLE IF NOT EXISTS car_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    car_id UUID NOT NULL REFERENCES cars(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    ip_address VARCHAR(45),
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_car_views_car_id ON car_views(car_id);
