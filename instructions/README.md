# TurboCar

A second-hand car buying/selling Android app built with Flutter, following enterprise-level architecture and clean code principles.

## Project Overview

TurboCar is a marketplace application that allows users to buy and sell second-hand cars. The app follows a clean architecture pattern with clear separation of concerns across different layers.

## Features

- **User Authentication**: Login, signup, Google login, guest mode
- **Car Listings**: Browse, search, and filter cars
- **Saved Cars**: Save favorite cars for later
- **User Profile**: Manage profile, view posted cars, change password
- **Dark Mode**: Toggle between light and dark themes
- **Real-time Notifications**: Firebase Cloud Messaging integration
- **Chat**: Real-time messaging (coming soon)

## Architecture

The project follows Clean Architecture principles with the following structure:

```
lib/
├── core/           # Core utilities, constants, theme, network
├── data/           # Data layer (models, repositories, services)
├── domain/         # Domain layer (entities, use cases)
└── presentation/   # UI layer (pages, widgets)
```

### Layer Responsibilities

- **Presentation Layer**: UI components, pages, and widgets
- **Domain Layer**: Business entities and use cases
- **Data Layer**: API services, repositories, data models

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Navigation**: go_router
- **HTTP Client**: Dio with Retrofit
- **Storage**: flutter_secure_storage, shared_preferences
- **Image Loading**: cached_network_image
- **Notifications**: Firebase Cloud Messaging
- **Code Generation**: build_runner, retrofit_generator, json_serializable

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd turbo_car
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

5. **Update API Configuration**
   - Update `lib/core/constants/api_constants.dart` with your API base URL

6. **Run the app**
   ```bash
   flutter run
   ```

## Folder Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/     # App constants (API, storage keys, strings)
│   ├── theme/         # Theme configuration
│   ├── utils/         # Validators, helpers, extensions
│   ├── network/       # Network configuration (Dio, interceptors)
│   └── router/        # Navigation configuration
├── data/
│   ├── models/        # Data models with JSON serialization
│   ├── repositories/  # Data repositories
│   ├── services/      # API service, storage, Firebase, Socket
│   └── providers/     # Riverpod state providers
├── domain/
│   ├── entities/      # Domain entities
│   └── usecases/      # Business logic use cases
└── presentation/
    ├── pages/         # Screen pages
    └── widgets/       # Reusable widgets
```

## State Management Flow

The app uses Riverpod for state management:

1. **Providers**: Defined in `data/providers/`
2. **State Notifiers**: Handle state changes
3. **Widgets**: Consume providers using `ConsumerWidget` or `Consumer`

## Navigation Flow

Navigation is handled by go_router:

- Routes are defined in `core/router/app_router.dart`
- Route names are constants in `core/router/route_names.dart`
- Navigation guards handle authentication checks

## API Integration

- API endpoints are defined in `core/constants/api_constants.dart`
- API service is generated using Retrofit
- Authentication tokens are handled by interceptors
- Error handling is centralized in network exceptions

## Error Handling

- Custom exception classes in `core/network/network_exceptions.dart`
- API interceptor handles HTTP errors
- User-friendly error messages displayed via snackbars

## Testing

Test structure is set up in:
- `test/unit/` - Unit tests
- `test/widget/` - Widget tests
- `test/integration/` - Integration tests

## Code Generation

Run code generation after modifying:
- Models with `@JsonSerializable`
- API service with Retrofit annotations
- Riverpod providers with `@riverpod` annotation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Coding Conventions

- Follow Flutter style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Use const constructors where possible

## TODO

- [ ] Complete chat functionality
- [ ] Complete post car functionality
- [ ] Complete notification handling
- [ ] Add unit tests
- [ ] Add widget tests
- [ ] Complete API integration
- [ ] Add error tracking (Sentry/Crashlytics)
- [ ] Add analytics

## License

This project is private and not licensed for public use.
