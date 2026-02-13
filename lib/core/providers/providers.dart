/// Providers Setup
/// Centralized provider initialization for dependency injection
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/car_repository.dart';
import '../../data/repositories/user_repository.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DioClient(storageService);
});

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiService(dioClient);
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(dioClient, storageService);
});

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(authService, storageService);
});

final carRepositoryProvider = Provider<CarRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CarRepository(apiService);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserRepository(authService);
});
