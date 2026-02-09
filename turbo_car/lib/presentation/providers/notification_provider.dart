/// Notification Provider
/// Riverpod provider for notification service
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/storage_service.dart';
import '../providers/chat_provider.dart';

/// Notification service singleton provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Storage key for notifications
const _notificationsStorageKey = 'app_notifications';

/// Notification list state
class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotificationListState({
    this.notifications = const [],
    this.isLoading = false,
  });

  NotificationListState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) {
    return NotificationListState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get unread count
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

/// Notification list notifier - manages local notification storage
class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final StorageService _storageService;

  NotificationListNotifier(this._storageService)
    : super(const NotificationListState()) {
    _loadFromStorage();
  }

  /// Load notifications from local storage
  Future<void> _loadFromStorage() async {
    state = state.copyWith(isLoading: true);
    try {
      final jsonString = await _storageService.read(_notificationsStorageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final notifications = jsonList
            .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
            .toList();
        // Sort by createdAt descending (newest first)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(notifications: notifications, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save notifications to local storage
  Future<void> _saveToStorage() async {
    try {
      final jsonList = state.notifications.map((n) => n.toJson()).toList();
      await _storageService.write(
        _notificationsStorageKey,
        json.encode(jsonList),
      );
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  /// Add a new notification (from FCM)
  void addNotification(NotificationModel notification) {
    final updated = [notification, ...state.notifications];
    // Keep only last 50 notifications
    final trimmed = updated.length > 50 ? updated.sublist(0, 50) : updated;
    state = state.copyWith(notifications: trimmed);
    _saveToStorage();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
    _saveToStorage();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
    _saveToStorage();
  }

  /// Clear all notifications
  void clearAll() {
    state = state.copyWith(notifications: []);
    _saveToStorage();
  }

  /// Remove a specific notification
  void removeNotification(String notificationId) {
    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();
    state = state.copyWith(notifications: updated);
    _saveToStorage();
  }
}

/// Provider for notification list
final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>((
      ref,
    ) {
      throw UnimplementedError('Must be overridden with storage service');
    });

/// FCM token provider - exposes the current token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  // Service should already be initialized in main.dart
  return service.fcmToken;
});

/// Notification tap handler
/// Listens to notification taps and navigates accordingly
class NotificationTapHandler {
  final Ref _ref;
  GoRouter? _router;

  NotificationTapHandler(this._ref);

  /// Set the router for navigation
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Start listening to notification taps
  void startListening() {
    final service = _ref.read(notificationServiceProvider);

    service.onNotificationTap.listen((data) {
      _handleNotificationTap(data);
    });
  }

  /// Handle notification tap based on type
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'chat_message':
        final conversationId = data['conversation_id'] as String?;
        if (conversationId != null && _router != null) {
          _router!.push('/chat/$conversationId');
        }
        break;

      case 'new_listing':
        final carId = data['car_id'] as String?;
        if (carId != null && _router != null) {
          _router!.push('/post/$carId');
        }
        break;

      case 'price_change':
        final carId = data['car_id'] as String?;
        if (carId != null && _router != null) {
          // Navigate to car details page
          _router!.push('/car-details/$carId');
        }
        break;

      default:
        // Navigate to notification page for other types
        _router?.push('/notification');
    }
  }
}

/// Provider for notification tap handler
final notificationTapHandlerProvider = Provider<NotificationTapHandler>((ref) {
  return NotificationTapHandler(ref);
});

/// Initialize notification service and register device token
Future<void> initializeNotifications(ProviderContainer container) async {
  final notificationService = container.read(notificationServiceProvider);

  // Initialize the service
  await notificationService.initialize();

  // Register FCM token with backend
  final token = notificationService.fcmToken;
  if (token != null) {
    try {
      final chatRepo = container.read(chatRepositoryProvider);
      // Determine device type
      final deviceType = _getDeviceType();
      await chatRepo.registerDevice(token, deviceType: deviceType);
    } catch (e) {
      // Token registration failed - will retry on next app start
      // This is non-critical, just log it
      debugPrint('Failed to register FCM token: $e');
    }
  }
}

String _getDeviceType() {
  // Platform detection
  try {
    if (identical(0, 0.0)) {
      return 'web';
    }
  } catch (_) {}

  // Use dart:io for native platforms
  return 'android'; // Default, will be overridden if iOS
}
