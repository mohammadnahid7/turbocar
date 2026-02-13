# Setup Guide

This guide will help you set up the Car Reselling Backend locally.

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 12 or higher
- Redis 6 or higher
- (Optional) Twilio account for SMS OTP

## Step 1: Clone and Navigate

```bash
cd car-reselling-backend
```

## Step 2: Install Dependencies

```bash
go mod download
go mod tidy
```

## Step 3: Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
SERVER_PORT=3000
DATABASE_URL=postgres://postgres:postgres@localhost:15432/car_reselling_db?sslmode=disable
REDIS_URL=redis://localhost:16379/0
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars
JWT_REFRESH_SECRET=your-refresh-secret-key-change-this-in-production-min-32-chars
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+1234567890
ENVIRONMENT=development
```

**Note:** Ports 15432 (PostgreSQL) and 16379 (Redis) are used to avoid conflicts with local services. See `PORTS.md` for details.

**Important:** 
- Generate strong, random secrets for `JWT_SECRET` and `JWT_REFRESH_SECRET` (minimum 32 characters)
- In development mode without Twilio, OTP codes will be printed to console

## Step 4: Set Up PostgreSQL

### Option A: Using Docker

```bash
docker run --name car-reselling-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=car_reselling_db \
  -p 15432:5432 \
  -d postgres:15-alpine
```

**Note:** Using port 15432 on host to avoid conflict with local PostgreSQL on 5432.

### Option B: Local PostgreSQL

1. Create database:
```bash
createdb car_reselling_db
```

2. Run migrations:
```bash
psql -U postgres -d car_reselling_db -f migrations/001_create_users_table.sql
```

## Step 5: Set Up Redis

### Option A: Using Docker

```bash
docker run --name car-reselling-redis \
  -p 16379:6379 \
  -d redis:7-alpine
```

**Note:** Using port 16379 on host to avoid conflict with local Redis on 6379.

### Option B: Local Redis

```bash
# On Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl start redis

# On macOS
brew install redis
brew services start redis
```

## Step 6: Run the Application

### Option A: Direct Run

```bash
go run cmd/api/main.go
```

### Option B: Using Make

```bash
make run
```

### Option C: Build and Run

```bash
make build
./bin/main
```

The server will start on `http://localhost:3000` (when using Docker) or `http://localhost:3000` (when running directly)

## Step 7: Verify Setup

Test the health endpoint:

```bash
# If using Docker Compose
curl http://localhost:3000/health

# If running directly
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy"
}
```

## Docker Compose Setup (Alternative)

For a complete setup with all services:

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## Testing the API

### 1. Register a User

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "phone": "+1234567890",
    "password": "Test1234",
    "full_name": "Test User"
  }'
```

**Note:** In development mode without Twilio, check the console output for the OTP code.

### 2. Verify OTP

```bash
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+1234567890",
    "code": "123456"
  }'
```

### 3. Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email_or_phone": "test@example.com",
    "password": "Test1234"
  }'
```

Save the `access_token` from the response.

### 4. Get Current User

```bash
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer <your_access_token>"
```

## Troubleshooting

### Database Connection Error

- Verify PostgreSQL is running: `pg_isready`
- Check `DATABASE_URL` in `.env` matches your PostgreSQL configuration
- Ensure database `car_reselling_db` exists

### Redis Connection Error

- Verify Redis is running: `redis-cli ping` (should return `PONG`)
- Check `REDIS_URL` in `.env` is correct

### Port Already in Use

- Change `SERVER_PORT` in `.env` to a different port
- Or stop the process using port 3000

### Migration Errors

- Ensure PostgreSQL has the `uuid-ossp` extension enabled
- Check that you have proper permissions on the database

## Development Tips

1. **OTP in Development:** Without Twilio configured, OTP codes are printed to console
2. **Hot Reload:** Use tools like `air` or `realize` for automatic reloading during development
3. **Database Migrations:** GORM auto-migrates on startup, but manual migrations are in `migrations/`
4. **Logging:** Set `ENVIRONMENT=development` for verbose logging

## Next Steps

- Review `API_DOCUMENTATION.md` for complete API reference
- Set up Twilio for production SMS OTP
- Configure proper CORS for your frontend domain
- Set up CI/CD pipeline
- Add monitoring and logging (e.g., Prometheus, Grafana)

