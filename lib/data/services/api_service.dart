/// API Service
/// API service for all endpoints using Dio
library;

import '../models/car_model.dart';
import '../models/notification_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  // Car endpoints
  Future<Map<String, dynamic>> getCars(Map<String, dynamic> queryParams) async {
    final response = await _dioClient.get(
      ApiConstants.cars,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<CarModel> getCarById(String id) async {
    final response = await _dioClient.get(ApiConstants.carById(id));
    return CarModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CarModel> createCar(Map<String, dynamic> carData) async {
    final response = await _dioClient.post(ApiConstants.cars, data: carData);
    return CarModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CarModel> updateCar(String id, Map<String, dynamic> carData) async {
    final response = await _dioClient.put(
      ApiConstants.carById(id),
      data: carData,
    );
    return CarModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCar(String id) async {
    await _dioClient.delete(ApiConstants.carById(id));
  }

  Future<List<CarModel>> getMyListings() async {
    final response = await _dioClient.get(ApiConstants.myListings);
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CarModel>> getFavorites() async {
    final response = await _dioClient.get(ApiConstants.favorites);
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Favorite endpoints
  Future<void> toggleFavorite(String carId) async {
    await _dioClient.post(ApiConstants.toggleFavorite(carId));
  }

  Future<void> incrementView(String carId) async {
    await _dioClient.post('${ApiConstants.cars}/$carId/view');
  }

  // Notification endpoints
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dioClient.get(ApiConstants.notifications);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _dioClient.put(ApiConstants.markNotificationRead(id));
  }
}
