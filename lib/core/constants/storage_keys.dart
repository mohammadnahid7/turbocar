/// Storage Keys
/// Contains all keys used for secure storage and shared preferences
library;

class StorageKeys {
  // Authentication
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';

  // Settings
  static const String themePreference = 'theme_preference';
  static const String languagePreference = 'language_preference';

  // App State
  static const String isGuestMode = 'is_guest_mode';
  static const String isFirstLaunch = 'is_first_launch';

  // Firebase
  static const String fcmToken = 'fcm_token';
}
