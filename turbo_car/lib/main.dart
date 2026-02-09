/// Main Entry Point
/// Application initialization and startup
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/firebase_service.dart';
import 'data/services/storage_service.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/car_provider.dart';
import 'data/providers/post_car_provider.dart';
import 'data/providers/saved_cars_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/car_image_provider.dart';
import 'core/providers/providers.dart';
import 'core/services/car_image_service.dart';
import 'core/services/notification_service.dart';
import 'presentation/providers/notification_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseService.initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize notification service (FCM)
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print(
      'Notification service initialized, FCM token: ${notificationService.fcmToken}',
    );
  } catch (e) {
    print('Notification service initialization error: $e');
  }

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Override storage service with initialized instance
        storageServiceProvider.overrideWithValue(storageService),
        // Override providers with actual implementations
        // Override providers with actual implementations
        authProvider.overrideWith((ref) {
          final authRepository = ref.watch(authRepositoryProvider);
          final storageService = ref.watch(storageServiceProvider);
          // We need access to SavedCarsNotifier for syncing on login
          final savedCarsNotifier = ref.watch(savedCarsProvider.notifier);
          // We need access to CarListNotifier for clearing on logout
          final carListNotifier = ref.watch(carListProvider.notifier);

          final notifier = AuthNotifier(
            authRepository,
            storageService,
            savedCarsNotifier,
            carListNotifier: carListNotifier,
          );
          notifier.checkAuthStatus();
          return notifier;
        }),
        carImageServiceProvider.overrideWith((ref) {
          final dioClient = ref.watch(dioClientProvider);
          return CarImageService(dio: dioClient.dio);
        }),
        carListProvider.overrideWith((ref) {
          final carRepository = ref.watch(carRepositoryProvider);
          final carImageService = ref.watch(carImageServiceProvider.notifier);
          return CarListNotifier(carRepository, carImageService);
        }),
        savedCarsProvider.overrideWith((ref) {
          final carRepository = ref.watch(carRepositoryProvider);
          final storageService = ref.watch(storageServiceProvider);
          final notifier = SavedCarsNotifier(
            carRepository,
            storageService,
            ref,
          );
          // Eager load saved cars from SecureStore on app start
          notifier.initFromStorage();
          return notifier;
        }),
        themeProvider.overrideWith((ref) {
          final storageService = ref.watch(storageServiceProvider);
          return ThemeNotifier(storageService);
        }),
        userProvider.overrideWith((ref) {
          final userRepository = ref.watch(userRepositoryProvider);
          return UserNotifier(userRepository);
        }),
        postCarProvider.overrideWith((ref) {
          final dioClient = ref.watch(dioClientProvider);
          return PostCarNotifier(dioClient);
        }),
        notificationListProvider.overrideWith((ref) {
          final storageService = ref.watch(storageServiceProvider);
          return NotificationListNotifier(storageService);
        }),
      ],
      child: const App(),
    ),
  );
}
