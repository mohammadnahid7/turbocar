/// Saved Cars Provider
/// Offline-First Architecture: SecureStore is the primary data source
/// Server is only used for sync on login and background operations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/car_model.dart';
import '../repositories/car_repository.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';

// Saved Cars State
class SavedCarsState {
  final List<CarModel> cars;
  final bool isInitialized;
  final String? error;

  SavedCarsState({
    this.cars = const [],
    this.isInitialized = false,
    this.error,
  });

  SavedCarsState copyWith({
    List<CarModel>? cars,
    bool? isInitialized,
    String? error,
  }) {
    return SavedCarsState(
      cars: cars ?? this.cars,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }

  /// Check if a car is saved by ID
  bool isCarSaved(String carId) {
    return cars.any((car) => car.id == carId);
  }
}

// Saved Cars Notifier - Offline-First Implementation
class SavedCarsNotifier extends StateNotifier<SavedCarsState> {
  final CarRepository _carRepository;
  final StorageService _storageService;
  final Ref _ref;

  SavedCarsNotifier(this._carRepository, this._storageService, this._ref)
    : super(SavedCarsState());

  /// Initialize from SecureStore - Called on app start
  /// This is the ONLY way to populate initial data
  Future<void> initFromStorage() async {
    if (state.isInitialized) return; // Already initialized

    try {
      final localCars = await _storageService.getSavedCars();
      state = state.copyWith(cars: localCars, isInitialized: true);
      debugPrint('SavedCars: Loaded ${localCars.length} cars from SecureStore');
    } catch (e) {
      debugPrint('SavedCars: Error loading from SecureStore: $e');
      state = state.copyWith(
        cars: [],
        isInitialized: true,
        error: e.toString(),
      );
    }
  }

  /// Sync on Login - Merges local cars with server cars
  /// Called ONCE when user logs in or signs up
  Future<void> syncOnLogin() async {
    try {
      // 1. Get current local saved cars (may include guest saves)
      final localCars = List<CarModel>.from(state.cars);
      final localCarIds = localCars.map((c) => c.id).toSet();

      debugPrint(
        'SavedCars: Syncing on login. Local cars: ${localCars.length}',
      );

      // 2. Fetch server saved cars
      final serverCars = await _carRepository.fetchFavorites();
      debugPrint('SavedCars: Server cars: ${serverCars.length}');

      // 3. Merge: Add server cars that aren't already local
      for (final serverCar in serverCars) {
        if (!localCarIds.contains(serverCar.id)) {
          localCars.add(serverCar.copyWith(isFavorited: true));
        }
      }

      // 4. Upload local-only cars to server (cars saved as guest)
      final serverCarIds = serverCars.map((c) => c.id).toSet();
      for (final localCar in state.cars) {
        if (!serverCarIds.contains(localCar.id)) {
          // This car was saved locally but not on server - upload it
          try {
            await _carRepository.toggleFavorite(localCar.id);
            debugPrint(
              'SavedCars: Uploaded local car ${localCar.id} to server',
            );
          } catch (e) {
            debugPrint('SavedCars: Failed to upload car ${localCar.id}: $e');
            // Continue - don't fail the whole sync
          }
        }
      }

      // 5. Save merged list to SecureStore
      await _storageService.saveSavedCars(localCars);

      // 6. Update state
      state = state.copyWith(cars: localCars);
      debugPrint('SavedCars: Sync complete. Total cars: ${localCars.length}');
    } catch (e) {
      debugPrint('SavedCars: Sync failed: $e');
      // Keep local data intact - don't clear it
      state = state.copyWith(error: e.toString());
    }
  }

  /// Save a car - Adds to SecureStore immediately, syncs to server in background
  Future<void> saveCar(CarModel car) async {
    // 1. Check for duplicates
    if (state.isCarSaved(car.id)) {
      debugPrint('SavedCars: Car ${car.id} already saved, skipping');
      return;
    }

    // 2. Add to local state immediately
    final updatedCars = [...state.cars, car.copyWith(isFavorited: true)];
    state = state.copyWith(cars: updatedCars);

    // 3. Save to SecureStore immediately
    await _storageService.saveSavedCars(updatedCars);
    debugPrint('SavedCars: Saved car ${car.id} to SecureStore');

    // 4. Sync to server in background (only if logged in)
    _syncToServerInBackground(car.id, isSaving: true);
  }

  /// Unsave a car - Removes from SecureStore immediately, syncs to server in background
  Future<void> unsaveCar(String carId) async {
    // 1. Check if car exists
    if (!state.isCarSaved(carId)) {
      debugPrint('SavedCars: Car $carId not found, skipping unsave');
      return;
    }

    // 2. Remove from local state immediately
    final updatedCars = state.cars.where((c) => c.id != carId).toList();
    state = state.copyWith(cars: updatedCars);

    // 3. Save to SecureStore immediately
    await _storageService.saveSavedCars(updatedCars);
    debugPrint('SavedCars: Removed car $carId from SecureStore');

    // 4. Sync to server in background (only if logged in)
    _syncToServerInBackground(carId, isSaving: false);
  }

  /// Toggle save state - Convenience method
  Future<bool> toggleSave(String carId, {CarModel? car}) async {
    if (state.isCarSaved(carId)) {
      await unsaveCar(carId);
      return false; // Now unsaved
    } else if (car != null) {
      await saveCar(car);
      return true; // Now saved
    }
    return false;
  }

  /// Background server sync - Never blocks UI
  void _syncToServerInBackground(String carId, {required bool isSaving}) {
    final authState = _ref.read(authProvider);

    // Skip server sync for guests
    if (authState.isGuest) {
      debugPrint('SavedCars: Guest mode - skipping server sync');
      return;
    }

    // Fire and forget - don't await
    _carRepository
        .toggleFavorite(carId)
        .then((_) {
          debugPrint('SavedCars: Server sync successful for car $carId');
        })
        .catchError((e) {
          debugPrint('SavedCars: Server sync failed for car $carId: $e');
          // Don't revert local state - SecureStore is source of truth
          // Could implement a retry queue here in the future
        });
  }

  /// Refresh saved cars from server (pull-to-refresh)
  Future<void> refresh() async {
    // Only works if logged in
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated || authState.isGuest) {
      // For guests, we can't fetch from server, so maybe just reload from storage?
      // Or do nothing as guest data is local-only.
      return;
    }

    try {
      // Fetch fresh data from server
      final serverCars = await _carRepository.fetchFavorites();

      // Update local state (maintaining local-only/guest cars if any?
      // Actually, if logged in, server should be source of truth + local unsynced variations.
      // For simplicity and correctness with "refresh", we trust server data for price updates.
      // But we should be careful not to wipe out pending local changes if any.
      // Given the syncOnLogin logic, we can probably just replace the list
      // or merge based on IDs to preserve local ordering if needed.
      // Let's replace to ensure prices are fresh.

      final freshCars = serverCars
          .map((c) => c.copyWith(isFavorited: true))
          .toList();

      state = state.copyWith(cars: freshCars);
      await _storageService.saveSavedCars(freshCars);
      debugPrint('SavedCars: Refreshed ${freshCars.length} cars from server');
    } catch (e) {
      debugPrint('SavedCars: Refresh failed: $e');
      // existing data is kept
    }
  }

  /// Update price of a saved car (triggered by notification)
  Future<void> updateCarPrice(String carId, double newPrice) async {
    if (!state.isCarSaved(carId)) return;

    final updatedCars = state.cars.map((car) {
      if (car.id == carId) {
        return car.copyWith(price: newPrice);
      }
      return car;
    }).toList();

    state = state.copyWith(cars: updatedCars);
    await _storageService.saveSavedCars(updatedCars);
    debugPrint('SavedCars: Updated price for car $carId to $newPrice');
  }

  /// Remove saved car - Alias for unsaveCar (used by SavedPage)
  Future<void> removeSavedCar(String carId) async {
    await unsaveCar(carId);
  }
}

// Saved Cars Provider - Override this in providers.dart
final savedCarsProvider =
    StateNotifierProvider<SavedCarsNotifier, SavedCarsState>((ref) {
      throw UnimplementedError(
        'SavedCarsProvider must be overridden in providers.dart',
      );
    });
