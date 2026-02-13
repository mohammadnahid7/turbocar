# Architecture Documentation

## Overview

TurboCar follows Clean Architecture principles with a clear separation of concerns across three main layers: Presentation, Domain, and Data.

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Pages, Widgets, State Management)     │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Domain Layer                  │
│      (Entities, Use Cases)              │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            Data Layer                   │
│  (Models, Repositories, Services)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      External Services                  │
│  (API, Storage, Firebase, Socket)       │
└─────────────────────────────────────────┘
```

## Layer Responsibilities

### Presentation Layer

**Location**: `lib/presentation/`

**Responsibilities**:
- UI rendering (pages and widgets)
- User interactions
- State management using Riverpod
- Navigation

**Key Components**:
- `pages/` - Screen implementations
- `widgets/` - Reusable UI components
- State providers consumed by widgets

**Data Flow**: Consumes Domain entities through providers, displays data to users, handles user input

### Domain Layer

**Location**: `lib/domain/`

**Responsibilities**:
- Business entities (pure Dart classes)
- Business logic use cases (if needed)

**Key Components**:
- `entities/` - Domain models (User, Car, Chat)
- `usecases/` - Business logic operations

**Data Flow**: Independent of framework, contains pure business logic

### Data Layer

**Location**: `lib/data/`

**Responsibilities**:
- Data models (with JSON serialization)
- API communication
- Local storage
- Data transformation (Model ↔ Entity)

**Key Components**:
- `models/` - Data models with JSON annotations
- `repositories/` - Data access abstraction
- `services/` - API service, storage, Firebase, Socket
- `providers/` - Riverpod state providers

**Data Flow**: Fetches data from external sources, transforms to domain entities, provides to presentation layer

## State Management Flow

```
User Action → Widget → Provider (StateNotifier) → Repository → API/Storage
                                                      ↓
User Update ← Widget ← Provider (State) ← Repository ← Response
```

1. User interacts with UI
2. Widget calls provider method
3. Provider updates state and calls repository
4. Repository fetches/updates data
5. State updates trigger UI rebuild

## Navigation Flow

```
App Start → Router → Redirect Logic → Route Resolution → Page Widget
```

1. App initializes with go_router
2. Router checks authentication state
3. Redirects based on auth status
4. Resolves route to appropriate page
5. Renders page widget

## Data Flow from API to UI

```
API Response → Dio Interceptor → API Service → Repository → Provider → Widget
```

1. API returns JSON response
2. Interceptor processes response/errors
3. API service deserializes to model
4. Repository transforms to entity (if needed)
5. Provider updates state with data
6. Widget rebuilds with new data

## Error Handling Strategy

1. **Network Layer**: Custom exceptions in `network_exceptions.dart`
2. **API Interceptor**: Catches and transforms Dio errors
3. **Repository**: Handles exceptions, throws domain exceptions
4. **Provider**: Catches exceptions, updates error state
5. **Widget**: Displays error message to user

## Authentication Flow

```
App Start → Check Token → Validate Token → Load User → Set Auth State
                                         ↓ (Invalid)
                                    Clear Storage → Redirect to Login
```

1. App checks for stored token
2. Validates token with API
3. Loads user profile
4. Sets authentication state
5. Redirects based on auth status

## Caching Strategy

- **Secure Storage**: Authentication tokens, user data
- **Shared Preferences**: Theme preference, language, guest mode
- **In-Memory**: Provider state (Riverpod)
- **Image Cache**: cached_network_image handles image caching

## Dependency Injection

Providers are initialized in `main.dart` using Riverpod's ProviderScope:

```dart
ProviderScope(
  overrides: [
    storageServiceProvider.overrideWithValue(storageService),
    authProvider.overrideWith(...),
    // Other providers
  ],
  child: App(),
)
```

## Code Generation

- **Models**: `json_serializable` generates `fromJson`/`toJson`
- **API Service**: `retrofit_generator` generates API client
- **Providers**: `riverpod_generator` generates providers (if using annotations)

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

## Testing Strategy

- **Unit Tests**: Test repositories, use cases, utilities
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows

## Best Practices

1. **Separation of Concerns**: Each layer only knows about the layer below
2. **Dependency Inversion**: Depend on abstractions, not implementations
3. **Single Responsibility**: Each class has one reason to change
4. **Immutable State**: State objects are immutable, updated via copyWith
5. **Error Handling**: Errors are handled at appropriate layers
6. **Code Reusability**: Common widgets and utilities are extracted

