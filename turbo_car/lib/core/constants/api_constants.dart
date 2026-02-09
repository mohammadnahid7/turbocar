/// API Constants
/// Contains all API endpoints, base URLs, and network-related constants
library;

class ApiConstants {
  // Base URL - TODO: Replace with actual API base URL
  // Use your computer's local IP for physical device
  // Both phone and computer must be on the same WiFi network
  // Use 10.0.2.2 for Android Emulator to access the host's localhost
  // static const String baseUrl = 'http://192.168.0.48:3000/api';
  // static const String baseUrl =
  //     'https://turbocar-backend-production.up.railway.app/api';
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String baseUrl = 'http://192.168.0.37:3000/api';
  // static const String baseUrl = 'http://172.30.1.12:8080/api';

  // WebSocket URL - derived from baseUrl (converts http→ws, https→wss)
  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    // Only include port for local development (non-standard ports like 3000, 8080, etc.)
    final hasExplicitPort = uri.hasPort && uri.port != 80 && uri.port != 443;
    final hostPart = hasExplicitPort ? '${uri.host}:${uri.port}' : uri.host;
    print('Hi Nahid: $hostPart');
    return '$wsScheme://$hostPart/api/chat/ws';
  }

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

  // User endpoints
  static const String me = '/auth/me';

  // Car endpoints
  static const String cars = '/cars';
  static String carById(String id) => '/cars/$id';
  static const String myListings = '/cars/my-listings';
  static const String favorites = '/cars/favorites';

  // Listing Actions
  static String toggleFavorite(String id) => '/cars/$id/favorite';

  // Chat endpoints
  static const String chats = '/chats';
  static String chatWithUser(String userId) => '/chats/$userId';

  // Notification endpoints
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Header keys
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String bearerPrefix = 'Bearer';
}
