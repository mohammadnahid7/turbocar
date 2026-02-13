/// Firebase Service
/// Handles Firebase initialization and push notifications
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  static FirebaseMessaging? _messaging;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // Request permission for notifications
      await requestPermission();

      // Get FCM token
      final token = await getFCMToken();
      print('FCM Token: $token');

      // TODO: Store token to server

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // Request notification permission
  static Future<void> requestPermission() async {
    try {
      final settings = await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Permission status: ${settings?.authorizationStatus}');
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      print('Get FCM token error: $e');
      return null;
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    // TODO: Show in-app notification
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message: ${message.notification?.title}');
    // TODO: Handle background notification
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');
    // TODO: Navigate to appropriate screen
  }

  // Store token to server
  // TODO: Implement API call to store FCM token
  static Future<void> storeTokenToServer(String token) async {
    // TODO: Call API to store token
  }
}
