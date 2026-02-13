/// Notification Service
/// Handles Firebase Cloud Messaging (FCM) and local notifications
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling background message: ${message.messageId}');
  // Note: Don't show local notification here, FCM handles it automatically
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Lazy initialization - don't access FirebaseMessaging until Firebase is initialized
  FirebaseMessaging? _messaging;
  FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  // Stream controller for received notifications
  final StreamController<RemoteMessage> _notificationReceivedController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onNotificationReceived =>
      _notificationReceivedController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification services
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up FCM handlers
    await _setupFCMHandlers();

    // Get FCM token
    await _getFCMToken();
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const chatChannel = AndroidNotificationChannel(
      'chat_messages', // id
      'Chat Messages', // name
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
    );

    const priceAlertChannel = AndroidNotificationChannel(
      'price_alerts', // id
      'Price Alerts', // name
      description: 'Notifications for price changes on saved cars',
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(priceAlertChannel);
  }

  /// Set up FCM message handlers
  Future<void> _setupFCMHandlers() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // Check if app was opened from notification (terminated state)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        // TODO: Send new token to backend
      });

      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages - show local notification
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    // Add to stream for app to handle (store/update UI)
    _notificationReceivedController.add(message);

    final notification = message.notification;
    final data = message.data;

    // Show local notification for foreground messages
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'New Message',
        body: notification.body ?? '',
        payload: jsonEncode(data),
      );
    }
  }

  /// Handle notification tap when app was in background
  void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Process notification data and emit to stream
  void _handleNotificationData(Map<String, dynamic> data) {
    _notificationTapController.add(data);
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Show chat message notification with custom styling
  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderAvatarUrl,
  }) async {
    final payload = jsonEncode({
      'type': 'chat_message',
      'conversation_id': conversationId,
    });

    // Use conversation ID hash as notification ID so updates replace old ones
    final notificationId = conversationId.hashCode;

    await showLocalNotification(
      id: notificationId,
      title: senderName,
      body: message,
      payload: payload,
    );
  }

  /// Show price alert notification for favorited cars
  Future<void> showPriceAlertNotification({
    required String carId,
    required String title,
    required String body,
    String? oldPrice,
    String? newPrice,
  }) async {
    final payload = jsonEncode({
      'type': 'price_change',
      'car_id': carId,
      'old_price': oldPrice,
      'new_price': newPrice,
    });

    // Use car ID hash as notification ID
    final notificationId = carId.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Notifications for price changes on saved cars',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    await messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await messaging.unsubscribeFromTopic(topic);
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}
