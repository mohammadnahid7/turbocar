# Design Integration Guide

## Overview

This guide explains where and how to integrate design elements, replace dummy data, and customize the UI styling.

## Where to Add Design Elements

### 1. App Logo and Icons

**Location**: `assets/images/` and `assets/icons/`

**Steps**:
1. Add app logo to `assets/images/logo.png`
2. Add app icons to `assets/icons/`
3. Update `pubspec.yaml` if using custom asset paths
4. Replace logo placeholder in:
   - `lib/presentation/pages/profile/about_us_page.dart`
   - `lib/presentation/pages/auth/login_signup_page.dart`

### 2. Colors and Theme

**Location**: `lib/core/theme/app_colors.dart`

**Customization**:
```dart
// Light Theme Colors
static const Color lightPrimary = Color(0xFF1976D2); // Your primary color
static const Color lightSecondary = Color(0xFF03DAC6); // Your secondary color
// ... update other colors
```

**Theme Configuration**: `lib/core/theme/app_theme.dart`
- Modify color schemes
- Update component themes (buttons, text fields, cards)
- Adjust elevation and border radius

### 3. Typography

**Location**: `lib/core/theme/app_text_styles.dart`

**Customization**:
- Update font sizes, weights, and line heights
- Add custom font families (if using custom fonts)

**To add custom fonts**:
1. Add font files to `assets/fonts/`
2. Update `pubspec.yaml`:
```yaml
fonts:
  - family: YourFontFamily
    fonts:
      - asset: assets/fonts/YourFont-Regular.ttf
      - asset: assets/fonts/YourFont-Bold.ttf
        weight: 700
```
3. Update text styles to use custom font

### 4. Images

**Car Images**:
- Images are loaded from API URLs in `CarModel`
- Placeholder shown when image fails to load
- Configure in `lib/presentation/widgets/common/car_list_item.dart`

**Profile Pictures**:
- User profile pictures loaded from API
- Fallback to default icon if not available
- Location: `lib/presentation/pages/profile/profile_page.dart`

### 5. Icons

**Location**: Material Icons (built-in)

**To use custom icons**:
1. Add icon font files to `assets/fonts/`
2. Use `IconData` with custom font family
3. Or use `IconButton` with image assets

## Replacing Dummy Data

### 1. Cities List

**Location**: `lib/presentation/widgets/specific/filter_bottom_sheet.dart`

```dart
// Replace with actual cities from API or constants
final List<String> cities = ['City 1', 'City 2', 'City 3'];
```

**TODO**: Fetch cities from API or add to constants

### 2. Companies List

**Location**: `lib/presentation/widgets/specific/company_button_group.dart`

```dart
// Replace with actual companies from API or constants
final List<String> companies = ['Toyota', 'Honda', 'BMW', ...];
```

**TODO**: Fetch companies from API or add to constants

### 3. Carousel Images

**Location**: `lib/presentation/pages/home/home_page.dart`

```dart
// TODO: Replace with actual carousel images from API
const ImageCarousel(
  images: [],
  // onTap: () => navigate to featured car,
);
```

**TODO**: Fetch featured car images from API

### 4. Contact Information

**Location**: `lib/presentation/pages/profile/contact_us_page.dart`

```dart
// Replace with actual phone number and email
subtitle: const Text('+1 234 567 8900'),
subtitle: const Text('support@turbocar.com'),
```

### 5. About Us Content

**Location**: `lib/presentation/pages/profile/about_us_page.dart`

Replace placeholder text with actual:
- App description
- Company information
- Terms and conditions link
- Privacy policy link

## Styling Guide

### Widget Styling

**Common Widgets** (in `lib/presentation/widgets/common/`):
- `custom_button.dart`: Customize button styles
- `custom_text_field.dart`: Customize input field styles
- `car_list_item.dart`: Customize car card layout and styling

### Component Themes

**Location**: `lib/core/theme/app_theme.dart`

Customize:
- `elevatedButtonTheme`: Button styles
- `outlinedButtonTheme`: Outlined button styles
- `textButtonTheme`: Text button styles
- `inputDecorationTheme`: Text field styles
- `cardTheme`: Card styles

### Page-Specific Styling

Each page can have custom styling by:
1. Wrapping widgets with `Container` or `Padding`
2. Using `Theme.of(context)` for consistent styling
3. Creating page-specific theme overrides if needed

## Image Asset Integration

### Adding Images

1. Add images to `assets/images/`
2. Reference in code:
```dart
Image.asset('assets/images/your_image.png')
```

### Network Images

Images from API are loaded using `cached_network_image`:
```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => LoadingIndicator(),
  errorWidget: (context, url, error) => ErrorIcon(),
)
```

## Font Integration

1. **Download Fonts**: Get font files (.ttf or .otf)
2. **Add to Project**: Place in `assets/fonts/`
3. **Update pubspec.yaml**: Add font configuration
4. **Use in Code**:
```dart
Text(
  'Your Text',
  style: TextStyle(
    fontFamily: 'YourFontFamily',
    fontSize: 16,
  ),
)
```

## Color Scheme Customization

### Light Theme

Update colors in `app_colors.dart`:
```dart
static const Color lightPrimary = Color(0xFFYourColor);
static const Color lightBackground = Color(0xFFYourColor);
// ... etc
```

### Dark Theme

Update dark theme colors:
```dart
static const Color darkPrimary = Color(0xFFYourColor);
static const Color darkBackground = Color(0xFFYourColor);
// ... etc
```

## Design System

### Spacing

Use consistent spacing:
- Small: 8px
- Medium: 16px
- Large: 24px
- XL: 32px

### Border Radius

- Small: 8px (buttons, text fields)
- Medium: 12px (cards)
- Large: 16px (modals)

### Elevation

- Cards: 2-4
- Buttons: 0 (flat) or 2 (elevated)
- AppBar: 0-1

## Responsive Design

Use `MediaQuery` for responsive layouts:

```dart
final screenWidth = MediaQuery.of(context).size.width;
final screenHeight = MediaQuery.of(context).size.height;

// Responsive padding
padding: EdgeInsets.all(screenWidth * 0.05)
```

## Animation and Transitions

Add animations where appropriate:
- Page transitions (handled by go_router)
- Loading indicators
- Button press feedback
- List item animations

## Accessibility

Ensure:
- Sufficient color contrast
- Touch target sizes (min 48x48)
- Semantic labels
- Screen reader support

## TODO Comments in Code

Search for "TODO" comments throughout the codebase to find places where:
- Design elements need to be connected
- API data needs to be integrated
- Styling needs to be customized

Common TODO locations:
- Widget files: Design connection points
- Page files: API data integration
- Service files: API endpoint configuration

