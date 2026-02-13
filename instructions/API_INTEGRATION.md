# API Integration Guide

## Overview

The app uses Retrofit with Dio for API communication. All API endpoints are defined in the API service, and network configuration is handled through interceptors.

## Setup

### 1. API Base URL

Update the base URL in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://your-api-domain.com/v1';
```

### 2. API Endpoints

All endpoints are defined in `lib/core/constants/api_constants.dart`:

- Authentication: `/auth/login`, `/auth/signup`, etc.
- User: `/user/profile`, `/user/change-password`
- Cars: `/cars`, `/cars/:id`, etc.
- Favorites: `/favorites/:carId`
- Chats: `/chats`, `/chats/:userId`
- Notifications: `/notifications`

### 3. API Service

The API service is defined in `lib/data/services/api_service.dart` using Retrofit annotations:

```dart
@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiService {
  @POST(ApiConstants.login)
  Future<Map<String, dynamic>> login(@Body() Map<String, dynamic> credentials);
  // ... other endpoints
}
```

## Request/Response Format

### Authentication Request

**Login**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Signup**:
```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "dateOfBirth": "1990-01-01T00:00:00Z",
  "gender": "Male"
}
```

**Response**:
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "user@example.com",
    // ... other user fields
  }
}
```

### Car List Request

**Query Parameters**:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)
- `city`: Filter by city
- `category`: Filter by category
- `priceMin`: Minimum price
- `priceMax`: Maximum price
- `sortBy`: Sort option (priceHigh, priceLow, mileage, year)
- `search`: Search query

**Response**:
```json
{
  "cars": [
    {
      "id": "car_id",
      "title": "2020 Toyota Camry",
      "description": "Car description...",
      "price": 25000,
      "year": 2020,
      "mileage": 30000,
      "company": "Toyota",
      "category": "Sedan",
      "city": "New York",
      "images": ["url1", "url2"],
      "userId": "user_id",
      "isSaved": false,
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "hasMore": true,
  "total": 100
}
```

## Authentication Token Handling

### Token Storage

Tokens are stored securely using `flutter_secure_storage`:

```dart
await storageService.saveToken(token);
```

### Token Injection

The API interceptor (`lib/core/network/api_interceptor.dart`) automatically adds the token to requests:

```dart
options.headers[ApiConstants.authorizationHeader] = 
    '${ApiConstants.bearerPrefix} $token';
```

### Token Refresh

Token refresh logic should be implemented in the interceptor's `onError` method. Currently, it's a TODO.

## Error Response Handling

### Error Format

Expected error response format:
```json
{
  "message": "Error message here",
  "code": "ERROR_CODE"
}
```

### Error Handling Flow

1. API returns error response
2. Dio interceptor catches error
3. Custom exception is created (`network_exceptions.dart`)
4. Repository catches exception
5. Provider updates error state
6. Widget displays error to user

### HTTP Status Codes

- `400`: BadRequestException
- `401`: UnauthorizedException (token refresh or logout)
- `404`: NotFoundException
- `500+`: InternalServerErrorException

## Testing with Mock Data

To test with mock data without a backend:

1. Create a mock API service
2. Override the API service provider
3. Return mock data from mock service

Example:
```dart
final mockApiService = MockApiService();
// Override provider with mock service
```

## Environment Configuration

Create environment configuration files:

**Development**:
```dart
static const String baseUrl = 'https://dev-api.example.com/v1';
```

**Production**:
```dart
static const String baseUrl = 'https://api.example.com/v1';
```

Use environment variables or build flavors to switch between environments.

## Request/Response Logging

Enable logging in `lib/core/network/dio_client.dart`:

```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  error: true,
));
```

**Note**: Disable logging in production builds.

## Timeout Configuration

Timeouts are configured in `ApiConstants`:

```dart
static const Duration connectTimeout = Duration(seconds: 30);
static const Duration receiveTimeout = Duration(seconds: 30);
static const Duration sendTimeout = Duration(seconds: 30);
```

## Code Generation

After updating the API service, regenerate code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Best Practices

1. **Error Handling**: Always handle errors at the repository level
2. **Token Management**: Store tokens securely, refresh when expired
3. **Request Validation**: Validate request data before sending
4. **Response Validation**: Validate response structure
5. **Loading States**: Show loading indicators during API calls
6. **Caching**: Cache responses when appropriate
7. **Retry Logic**: Implement retry for failed requests
8. **Logging**: Log requests/responses in debug mode only

