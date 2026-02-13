# Car Reselling Backend

A high-performance backend for a second-hand car reselling marketplace built with Go, PostgreSQL, and Redis.

## Features

- JWT-based authentication with refresh tokens
- OTP verification via SMS (Twilio)
- User registration and login
- Rate limiting
- Redis caching for sessions and OTP
- PostgreSQL for persistent data storage

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 12 or higher
- Redis 6 or higher
- Twilio account (for SMS OTP)

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd car-reselling-backend
```

2. Install dependencies:
```bash
go mod download
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run database migrations:
```bash
# Make sure PostgreSQL is running
psql -U postgres -d car_reselling_db -f migrations/001_create_users_table.sql
```

5. Run the application:
```bash
go run cmd/api/main.go
```

## Port Configuration

**Important:** This project uses non-standard ports to avoid conflicts:
- **API Server:** `http://localhost:3000` (Docker) or `http://localhost:3000` (direct)
- **PostgreSQL:** Port `15432` (host) → `5432` (container)
- **Redis:** Port `16379` (host) → `6379` (container)

See `PORTS.md` for complete port documentation.

## API Documentation & Testing

### Swagger UI (Interactive API Testing)

**Access the interactive Swagger documentation at:**
- **http://localhost:3000/swagger/index.html** (Docker)
- **http://localhost:3000/swagger/index.html** (direct)

Swagger UI provides:
- ✅ Interactive API testing directly in your browser
- ✅ Complete API documentation with examples
- ✅ JWT authentication support
- ✅ Request/response schemas
- ✅ Try it out functionality

See `SWAGGER_GUIDE.md` for detailed usage instructions.

### API Endpoints

Base URL: `http://localhost:3000` (Docker) or `http://localhost:3000` (direct)

#### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login with email/phone and password
- `POST /api/auth/send-otp` - Send OTP to phone number
- `POST /api/auth/verify-otp` - Verify OTP code
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Logout (requires authentication)
- `GET /api/auth/me` - Get current user (requires authentication)

## Development

### Running Tests
```bash
go test ./...
```

### Building
```bash
go build -o main cmd/api/main.go
```

## Docker

```bash
docker-compose up -d
```

## License

MIT

