import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/car_image_service.dart';

/// Provider for CarImageService
/// We override this in main.dart
final carImageServiceProvider =
    StateNotifierProvider<CarImageService, Map<String, String>>((ref) {
      throw UnimplementedError(
        'CarImageServiceProvider must be overridden in main.dart',
      );
    });
