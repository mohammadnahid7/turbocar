/// Car Provider
/// State management for car listings using Riverpod with caching support
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../repositories/car_repository.dart';
import '../../core/services/car_image_service.dart';
import '../../core/constants/app_constants.dart';

// Car List State
class CarListState {
  final bool isLoading;
  final List<CarModel> cars;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final Map<String, dynamic>? filters;
  final bool hasCachedData; // Indicates if cars list has cached data

  CarListState({
    this.isLoading = false,
    this.cars = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.error,
    this.filters,
    this.hasCachedData = false,
  });

  CarListState copyWith({
    bool? isLoading,
    List<CarModel>? cars,
    int? currentPage,
    bool? hasMore,
    String? error,
    Map<String, dynamic>? filters,
    bool? hasCachedData,
  }) {
    return CarListState(
      isLoading: isLoading ?? this.isLoading,
      cars: cars ?? this.cars,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filters: filters ?? this.filters,
      hasCachedData: hasCachedData ?? this.hasCachedData,
    );
  }
}

// Car List Notifier
class CarListNotifier extends StateNotifier<CarListState> {
  final CarRepository _carRepository;
  final CarImageService _carImageService;

  CarListNotifier(this._carRepository, this._carImageService)
    : super(CarListState());

  // Fetch cars with filters - supports caching
  Future<void> fetchCars({
    Map<String, dynamic>? filters,
    bool refresh = false,
    bool showCachedWhileLoading = true,
  }) async {
    // If we have cached data and showing cached while loading, don't clear cars
    if (refresh || !showCachedWhileLoading) {
      state = state.copyWith(
        isLoading: true,
        currentPage: 1,
        cars: refresh ? [] : state.cars, // Keep cached data if not refreshing
        hasMore: true,
        error: null,
      );
    } else {
      // Show loading indicator but keep existing cars (cached data)
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final queryParams = {
        'page': refresh ? 1 : state.currentPage,
        'limit': AppConstants.defaultPageSize,
        ...?filters,
        ...?state.filters,
      };

      final response = await _carRepository.fetchCars(queryParams);
      // Backend returns 'data' not 'cars'
      final cars = (response['data'] as List)
          .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Start background sequential download of thumbnails
      _carImageService.addToQueue(cars);

      final hasMore =
          response['has_more'] as bool? ??
          response['hasMore'] as bool? ??
          false;

      // Smart Diffing Logic
      List<CarModel> finalCars;
      if (refresh && state.cars.isNotEmpty) {
        final oldCarMap = {for (var c in state.cars) c.id: c};
        finalCars = cars.map((newCar) {
          final oldCar = oldCarMap[newCar.id];
          if (oldCar != null) {
            // Check if content is chemically equal
            // Note: We use toJson() for deep comparison since == is not overridden
            if (mapEquals(oldCar.toJson(), newCar.toJson())) {
              return oldCar; // Reuse existing instance to preserve image state
            }
          }
          return newCar;
        }).toList();
      } else {
        finalCars = refresh ? cars : [...state.cars, ...cars];
      }

      state = state.copyWith(
        isLoading: false,
        cars: finalCars,
        currentPage: refresh ? 1 : state.currentPage,
        hasMore: hasMore,
        filters: filters ?? state.filters,
        hasCachedData: true, // Mark as having cached data
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Search cars
  Future<void> searchCars(String query) async {
    if (query.isEmpty) {
      fetchCars(refresh: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = {
        'page': 1,
        'limit': AppConstants.defaultPageSize,
        'search': query,
        ...?state.filters,
      };

      final response = await _carRepository.fetchCars(queryParams);
      // Backend returns 'data' not 'cars'
      final cars = (response['data'] as List)
          .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        cars: cars,
        currentPage: 1,
        hasMore: false,
        hasCachedData: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Apply filters
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    await fetchCars(filters: filters, refresh: true);
  }

  // Reset filters
  Future<void> resetFilters() async {
    await fetchCars(filters: {}, refresh: true);
  }

  // Load more
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await fetchCars(refresh: false, showCachedWhileLoading: true);
  }

  // Reset state completely (call on logout or when clearing data)
  void reset() {
    state = CarListState();
  }

  // Toggle local favorite status (optimistic UI update)
  void toggleLocalFavorite(String carId) {
    final updatedCars = state.cars.map((car) {
      if (car.id == carId) {
        return car.copyWith(isFavorited: !car.isFavorited);
      }
      return car;
    }).toList();
    state = state.copyWith(cars: updatedCars);
  }
}

// Car List Provider - Override this in providers.dart
final carListProvider = StateNotifierProvider<CarListNotifier, CarListState>((
  ref,
) {
  throw UnimplementedError(
    'CarListProvider must be overridden in providers.dart',
  );
});
