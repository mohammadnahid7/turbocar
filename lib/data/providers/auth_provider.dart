/// Auth Provider
/// State management for authentication using Riverpod
library;

import 'dart:io';
import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/storage_service.dart';
import 'saved_cars_provider.dart';
import 'car_provider.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isGuest;
  final UserModel? user;
  final String? error;

  final bool isInitialized; // New flag

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isGuest = false,
    this.user,
    this.error,
    this.isInitialized = false, // Default false
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isGuest,
    UserModel? user,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      user: user ?? this.user,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;
  final SavedCarsNotifier _savedCarsNotifier;
  final CarListNotifier? _carListNotifier;

  AuthNotifier(
    this._authRepository,
    this._storageService,
    this._savedCarsNotifier, {
    CarListNotifier? carListNotifier,
  }) : _carListNotifier = carListNotifier,
       super(AuthState());

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.login(email, password);
      await _storageService.setGuestMode(false);

      // Sync saved cars on login (merges local + server)
      await _savedCarsNotifier.syncOnLogin();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isGuest: false,
        user: user,
      );
    } catch (e) {
      // IMPORTANT: Explicitly set isAuthenticated to false to prevent router redirect
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Extracts a user-friendly error message from various exception types
  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      // Check for our custom NetworkException inside DioException.error
      if (e.error != null && e.error is Exception) {
        return e.error.toString();
      }
      // Otherwise, try to get message from response body
      final responseData = e.response?.data;
      if (responseData is Map && responseData.containsKey('message')) {
        return responseData['message'].toString();
      }
      // Fallback to DioException message
      return e.message ?? 'Network error occurred';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  // Register
  Future<void> register({
    required String email,
    required String phone,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.register(
        email: email,
        phone: phone,
        password: password,
        fullName: fullName,
      );
      // Logic for after registration (e.g. login?) can also sync if needed
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      rethrow;
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      await _authRepository.sendOtp(phone);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    try {
      await _authRepository.verifyOtp(phone, code);
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      // Clear car list state to prevent doubling on re-login
      _carListNotifier?.reset();
      state = AuthState(isInitialized: true);
    } catch (e) {
      // Clear state even if API call fails
      _carListNotifier?.reset();
      state = AuthState(isInitialized: true);
      rethrow;
    }
  }

  // Switch to guest mode
  Future<void> switchToGuestMode() async {
    await _storageService.setGuestMode(true);
    state = state.copyWith(isAuthenticated: false, isGuest: true, user: null);
  }

  // Change Password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      rethrow;
    }
  }

  Future<String> uploadImage(File file) async {
    // Ideally this should be in a separate provider/service if used elsewhere
    // But since it's only here for now:
    try {
      return await _authRepository.uploadImage(file);
    } catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<void> updateProfile({
    String? fullName,
    String? gender,
    String? dob,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = <String, dynamic>{};
      if (fullName != null) userData['full_name'] = fullName;
      if (gender != null) userData['gender'] = gender;
      if (dob != null) userData['dob'] = dob;
      if (photoUrl != null) userData['profile_photo_url'] = photoUrl;

      final updatedUser = await _authRepository.updateProfile(userData);

      // Update local state
      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      rethrow;
    }
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storageService.getToken();
      final isGuest = await _storageService.isGuestMode();

      if (token != null && token.isNotEmpty && !isGuest) {
        final user = await _authRepository.getCurrentUser();

        // Sync saved cars if already logged in (optional but good for consistency)
        // _savedCarsNotifier.fetchSavedCars(forceSync: true);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isGuest: false,
          user: user,
          isInitialized: true,
        );
      } else if (isGuest) {
        state = state.copyWith(
          isLoading: false,
          isGuest: true,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(isLoading: false, isInitialized: true);
      }
    } catch (e) {
      // If token is invalid, clear it
      await _storageService.clearAll();
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }
}

// Auth Provider - Override this in providers.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  throw UnimplementedError('AuthProvider must be overridden in providers.dart');
});
