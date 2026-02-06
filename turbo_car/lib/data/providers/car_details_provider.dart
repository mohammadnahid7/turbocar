/// Car Details Provider
/// State management for single car details view
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../repositories/car_repository.dart';
import '../../core/providers/providers.dart';
import '../services/api_service.dart';

// Car Details State
class CarDetailsState {
  final bool isLoading;
  final CarModel? car;
  final String? error;

  CarDetailsState({this.isLoading = false, this.car, this.error});

  CarDetailsState copyWith({
    bool? isLoading,
    CarModel? car,
    String? error,
    bool clearError = false,
  }) {
    return CarDetailsState(
      isLoading: isLoading ?? this.isLoading,
      car: car ?? this.car,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Car Details Notifier
class CarDetailsNotifier extends StateNotifier<CarDetailsState> {
  final CarRepository _carRepository;

  CarDetailsNotifier(this._carRepository) : super(CarDetailsState());

  // Fetch car details by ID
  Future<void> fetchCarDetails(String carId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final car = await _carRepository.fetchCarById(carId);
      state = state.copyWith(isLoading: false, car: car);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Toggle favorite status (optimistic update)
  Future<void> toggleFavorite() async {
    if (state.car == null) return;

    final currentCar = state.car!;
    // Optimistic update
    state = state.copyWith(
      car: currentCar.copyWith(isFavorited: !currentCar.isFavorited),
    );

    try {
      await _carRepository.toggleFavorite(currentCar.id);
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        car: currentCar,
        error: 'Failed to update favorite status',
      );
    }
  }

  // Clear state
  void clear() {
    state = CarDetailsState();
  }
}

// Car Details Provider
final carDetailsProvider =
    StateNotifierProvider.autoDispose<CarDetailsNotifier, CarDetailsState>((
      ref,
    ) {
      final dioClient = ref.watch(dioClientProvider);
      final apiService = ApiService(dioClient);
      final carRepository = CarRepository(apiService);
      return CarDetailsNotifier(carRepository);
    });
