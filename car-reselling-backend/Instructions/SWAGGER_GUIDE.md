# Swagger API Documentation Guide

## Accessing Swagger UI

Once the API is running, access the interactive Swagger documentation at:

**http://localhost:3000/swagger/index.html**

## Features

Swagger UI provides:

1. **Interactive API Testing** - Test all endpoints directly from the browser
2. **Complete API Documentation** - All endpoints, request/response schemas
3. **Authentication Support** - Easy JWT token management
4. **Request/Response Examples** - See example payloads and responses
5. **Try It Out** - Execute API calls and see real responses

## How to Use

### 1. Open Swagger UI

Navigate to: `http://localhost:3000/swagger/index.html`

### 2. Test Public Endpoints

Start with public endpoints that don't require authentication:

- **POST /api/auth/register** - Register a new user
- **POST /api/auth/login** - Login and get tokens
- **POST /api/auth/send-otp** - Send OTP
- **POST /api/auth/verify-otp** - Verify OTP
- **POST /api/auth/refresh** - Refresh token
- **GET /health** - Health check

### 3. Authenticate for Protected Endpoints

To test protected endpoints (`/api/auth/logout`, `/api/auth/me`):

1. First, use `/api/auth/login` to get an access token
2. Click the **"Authorize"** button at the top of Swagger UI
3. Enter: `Bearer <your_access_token>` (include the word "Bearer" and a space)
4. Click **"Authorize"** then **"Close"**
5. Now you can test protected endpoints

### 4. Example Workflow

#### Step 1: Register a User
```json
POST /api/auth/register
{
  "email": "test@example.com",
  "phone": "+1234567890",
  "password": "Test1234",
  "full_name": "Test User"
}
```

#### Step 2: Verify OTP
Check the console logs for the OTP code (in development mode), then:
```json
POST /api/auth/verify-otp
{
  "phone": "+1234567890",
  "code": "123456"
}
```

#### Step 3: Login
```json
POST /api/auth/login
{
  "email_or_phone": "test@example.com",
  "password": "Test1234"
}
```

Copy the `access_token` from the response.

#### Step 4: Authorize in Swagger
1. Click **"Authorize"** button
2. Enter: `Bearer <paste_access_token_here>`
3. Click **"Authorize"**

#### Step 5: Test Protected Endpoints
- **GET /api/auth/me** - Get current user info
- **POST /api/auth/logout** - Logout

## Updating Swagger Documentation

If you modify API endpoints or add new ones:

1. Update Swagger annotations in your handler files
2. Regenerate docs:
   ```bash
   export PATH=$PATH:$(go env GOPATH)/bin
   swag init -g cmd/api/main.go -o docs --parseDependency --parseInternal
   ```
3. Rebuild and restart:
   ```bash
   docker-compose build api
   docker-compose up -d api
   ```

## Swagger Annotations Reference

### Endpoint Annotations
```go
// @Summary Short summary
// @Description Detailed description
// @Tags tag-name
// @Accept json
// @Produce json
// @Param name body Type true "Description"
// @Success 200 {object} ResponseType
// @Failure 400 {object} ErrorResponse
// @Router /path [method]
// @Security BearerAuth
```

### Model Annotations
```go
// @Description Model description
type Model struct {
    Field string `json:"field" example:"example value"`
}
```

## Troubleshooting

### Swagger UI Not Loading
- Check if API is running: `docker-compose ps`
- Check logs: `docker-compose logs api`
- Verify port: `curl http://localhost:3000/health`

### Authorization Not Working
- Make sure to include "Bearer " prefix before the token
- Check token hasn't expired (15 minutes for access tokens)
- Verify token format is correct

### Docs Not Updating
- Regenerate docs after code changes
- Rebuild Docker image
- Clear browser cache

## Alternative: Postman Collection

You can also export the Swagger spec and import it into Postman:

1. Get Swagger JSON: `http://localhost:3000/swagger/doc.json`
2. Import into Postman
3. Set up environment variables for tokens

## Benefits

✅ **No need for separate API client** - Test directly in browser  
✅ **Always up-to-date** - Generated from code annotations  
✅ **Interactive** - Try requests with real data  
✅ **Documentation** - Complete API reference  
✅ **Team-friendly** - Share with frontend developers  

Enjoy testing your APIs! 🚀

