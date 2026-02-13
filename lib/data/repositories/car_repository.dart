/// Car Repository
/// Handles car-related operations
library;

import '../models/car_model.dart';
import '../services/api_service.dart';

class CarRepository {
  final ApiService _apiService;

  CarRepository(this._apiService);

  // Fetch cars with filters
  Future<Map<String, dynamic>> fetchCars(Map<String, dynamic> filters) async {
    try {
      return await _apiService.getCars(filters);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch car by ID
  Future<CarModel> fetchCarById(String id) async {
    try {
      return await _apiService.getCarById(id);
    } catch (e) {
      rethrow;
    }
  }

  // Create car
  Future<CarModel> createCar(Map<String, dynamic> carData) async {
    try {
      return await _apiService.createCar(carData);
    } catch (e) {
      rethrow;
    }
  }

  // Update car
  Future<CarModel> updateCar(String id, Map<String, dynamic> carData) async {
    try {
      return await _apiService.updateCar(id, carData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete car
  Future<void> deleteCar(String id) async {
    try {
      await _apiService.deleteCar(id);
    } catch (e) {
      rethrow;
    }
  }

  // Increment view count
  Future<void> incrementView(String id) async {
    try {
      await _apiService.incrementView(id);
    } catch (e) {
      // Fail silently
      print('Failed to increment view: $e');
    }
  }

  // Fetch my listings
  Future<List<CarModel>> fetchMyListings() async {
    try {
      return await _apiService.getMyListings();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch favorites
  Future<List<CarModel>> fetchFavorites() async {
    try {
      return await _apiService.getFavorites();
    } catch (e) {
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String carId) async {
    try {
      await _apiService.toggleFavorite(carId);
    } catch (e) {
      rethrow;
    }
  }
}
