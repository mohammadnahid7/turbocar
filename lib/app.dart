/// App
/// Main app widget configuration
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'data/models/notification_model.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/theme_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/notification_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _hasRegisteredFcmToken = false;
  bool _isListeningForNotifications = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Register FCM token when user becomes authenticated
    // Use addPostFrameCallback to avoid calling during build
    if (authState.isAuthenticated && !_hasRegisteredFcmToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerFcmToken();
        _listenForNotifications();
      });
    } else if (!authState.isAuthenticated) {
      _hasRegisteredFcmToken = false; // Reset on logout
      _isListeningForNotifications = false;
    }

    return MaterialApp.router(
      title: 'TurboCar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _registerFcmToken() async {
    if (_hasRegisteredFcmToken) return;
    _hasRegisteredFcmToken = true;

    // Small delay to ensure Firebase is fully ready
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final notificationService = NotificationService();
      var fcmToken = notificationService.fcmToken;

      // If token not ready yet, wait a bit more and retry
      if (fcmToken == null) {
        await Future.delayed(const Duration(seconds: 1));
        fcmToken = notificationService.fcmToken;
      }

      if (fcmToken != null) {
        final chatRepo = ref.read(chatRepositoryProvider);
        await chatRepo.registerDevice(fcmToken, deviceType: 'android');
        debugPrint('FCM token registered with backend successfully');
      } else {
        debugPrint('FCM token still not available after retry');
        _hasRegisteredFcmToken = false; // Allow future retry
      }
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
      _hasRegisteredFcmToken = false; // Allow future retry
    }
  }

  void _listenForNotifications() {
    if (_isListeningForNotifications) return;
    _isListeningForNotifications = true;

    final notificationService = NotificationService();
    notificationService.onNotificationReceived.listen((message) {
      final notification = message.notification;

      if (notification != null) {
        final model = NotificationModel(
          id:
              message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: notification.title ?? 'New Notification',
          message: notification.body ?? '',
          type: message.data['type'] ?? 'general',
          createdAt: DateTime.now(),
          data: message.data,
          isRead: false,
        );

        ref.read(notificationListProvider.notifier).addNotification(model);
      }
    });

    // Also verify tap handler is listening
    ref.read(notificationTapHandlerProvider).startListening();
    ref
        .read(notificationTapHandlerProvider)
        .setRouter(ref.read(routerProvider));
  }
}
