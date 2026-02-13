/// App Constants
/// Contains application-wide constants like app name, version, limits, etc.
library;

class AppConstants {
  // App Information
  static const String appName = 'TurboCar';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 30;
  static const int maxPageSize = 100;

  // Image Configuration
  static const int maxImageSizeMB = 10;
  static const int maxImagesPerCar = 10;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;

  // Password Validation Rules
  static const int minPasswordLength = 8;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;

  // Price Range
  static const int minPrice = 0;
  static const int maxPrice = 100000000; // 100 million
  static const int priceStep = 100000;

  // Text Limits
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
  static const int maxNameLength = 50;

  // Date Constraints
  static const int minCarYear = 1900;
  static const int maxCarYear = 2025;
  static const int minUserAge = 18;

  // Search
  static const int searchDebounceMs = 500;
  static const int minSearchLength = 2;
}
