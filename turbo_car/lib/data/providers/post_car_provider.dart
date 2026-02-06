/// Post Car Provider
/// State management for posting a new car listing
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/car_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

// Post Car State
class PostCarState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final CarModel? postedCar;

  // Form fields
  final String carType;
  final String carName;
  final String carModel;
  final String fuelType;
  final int? mileage;
  final int? year;
  final double? price;
  final String description;
  final String condition;
  final String transmission;
  final String color;
  final String city;
  final String state;
  final bool chatOnly;
  final List<XFile> images;

  PostCarState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.postedCar,
    this.carType = '',
    this.carName = '',
    this.carModel = '',
    this.fuelType = 'petrol',
    this.mileage,
    this.year,
    this.price,
    this.description = '',
    this.condition = 'good',
    this.transmission = 'automatic',
    this.color = '',
    this.city = '',
    this.state = '',
    this.chatOnly = false,
    this.images = const [],
  });

  PostCarState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    CarModel? postedCar,
    String? carType,
    String? carName,
    String? carModel,
    String? fuelType,
    int? mileage,
    int? year,
    double? price,
    String? description,
    String? condition,
    String? transmission,
    String? color,
    String? city,
    String? state,
    bool? chatOnly,
    List<XFile>? images,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PostCarState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      postedCar: postedCar ?? this.postedCar,
      carType: carType ?? this.carType,
      carName: carName ?? this.carName,
      carModel: carModel ?? this.carModel,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      year: year ?? this.year,
      price: price ?? this.price,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      transmission: transmission ?? this.transmission,
      color: color ?? this.color,
      city: city ?? this.city,
      state: state ?? this.state,
      chatOnly: chatOnly ?? this.chatOnly,
      images: images ?? this.images,
    );
  }

  // Validation (only required fields)
  bool get isValid {
    return carType.isNotEmpty &&
        carName.isNotEmpty &&
        carModel.isNotEmpty &&
        fuelType.isNotEmpty &&
        mileage != null &&
        mileage! >= 0 &&
        year != null &&
        year! >= 1900 &&
        price != null &&
        price! > 0 &&
        description.length >= 20 &&
        city.isNotEmpty &&
        images.isNotEmpty;
  }

  // Generate title
  String get generatedTitle => '$carName $carModel $year'.trim();
}

// Post Car Notifier
class PostCarNotifier extends StateNotifier<PostCarState> {
  final DioClient _dioClient;

  PostCarNotifier(this._dioClient) : super(PostCarState());

  // Update form fields
  void updateCarType(String value) =>
      state = state.copyWith(carType: value, clearError: true);
  void updateCarName(String value) =>
      state = state.copyWith(carName: value, clearError: true);
  void updateCarModel(String value) =>
      state = state.copyWith(carModel: value, clearError: true);
  void updateFuelType(String value) =>
      state = state.copyWith(fuelType: value, clearError: true);
  void updateMileage(int? value) =>
      state = state.copyWith(mileage: value, clearError: true);
  void updateYear(int? value) =>
      state = state.copyWith(year: value, clearError: true);
  void updatePrice(double? value) =>
      state = state.copyWith(price: value, clearError: true);
  void updateDescription(String value) =>
      state = state.copyWith(description: value, clearError: true);
  void updateCondition(String value) =>
      state = state.copyWith(condition: value, clearError: true);
  void updateTransmission(String value) =>
      state = state.copyWith(transmission: value, clearError: true);
  void updateColor(String value) =>
      state = state.copyWith(color: value, clearError: true);
  void updateCity(String value) =>
      state = state.copyWith(city: value, clearError: true);
  void updateState(String value) =>
      state = state.copyWith(state: value, clearError: true);
  void updateChatOnly(bool value) =>
      state = state.copyWith(chatOnly: value, clearError: true);

  // Image management
  void addImage(XFile image) {
    final newImages = [...state.images, image];
    state = state.copyWith(images: newImages, clearError: true);
  }

  void removeImage(int index) {
    final newImages = [...state.images];
    newImages.removeAt(index);
    state = state.copyWith(images: newImages);
  }

  // Clear form
  void clearForm() {
    state = PostCarState();
  }

  // Clear messages
  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  // Submit car listing
  Future<bool> submitCar() async {
    if (!state.isValid) {
      state = state.copyWith(
        error: 'Please fill in all required fields correctly',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      // Build form data
      final formData = FormData();

      // Add text fields (only required fields)
      formData.fields.addAll([
        MapEntry('title', state.generatedTitle),
        MapEntry('description', state.description),
        MapEntry('make', state.carName),
        MapEntry('model', '${state.carType} ${state.carModel}'.trim()),
        MapEntry('year', state.year.toString()),
        MapEntry('mileage', state.mileage.toString()),
        MapEntry('price', state.price.toString()),
        MapEntry('fuel_type', state.fuelType),
        MapEntry('city', state.city),
        MapEntry('chat_only', state.chatOnly.toString()),
        // Optional fields are not sent (condition, transmission, color, state, lat, long)
      ]);

      // Add images as multipart files
      // Server will upload these to S3/R2 storage
      for (final image in state.images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ),
        );
      }

      // Make API call
      final response = await _dioClient.dio.post(
        ApiConstants.cars,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final car = CarModel.fromJson(response.data as Map<String, dynamic>);
        state = PostCarState(
          successMessage: 'Car posted successfully!',
          postedCar: car,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to post car. Please try again.',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to post car. Please try again.';
      if (e.response?.data != null && e.response?.data['error'] != null) {
        errorMessage = e.response?.data['error'].toString() ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

// Provider - will be overridden in providers.dart
final postCarProvider = StateNotifierProvider<PostCarNotifier, PostCarState>((
  ref,
) {
  throw UnimplementedError(
    'PostCarProvider must be overridden in providers.dart',
  );
});
