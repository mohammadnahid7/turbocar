/// Storage Service
/// Handles secure storage and shared preferences operations
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../core/constants/storage_keys.dart';
import '../models/user_model.dart';
import '../models/car_model.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize shared preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: StorageKeys.refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: StorageKeys.refreshToken);
  }

  // User Data Management
  Future<void> saveUserData(String userData) async {
    await _secureStorage.write(key: StorageKeys.userData, value: userData);
  }

  Future<void> saveUser(UserModel user) async {
    final userData = jsonEncode(user.toJson());
    await saveUserData(userData);
  }

  Future<String?> getUserData() async {
    return await _secureStorage.read(key: StorageKeys.userData);
  }

  Future<UserModel?> getUser() async {
    final userData = await getUserData();
    if (userData != null) {
      try {
        return UserModel.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearUserData() async {
    await _secureStorage.delete(key: StorageKeys.userData);
  }

  Future<void> deleteUser() async {
    await clearUserData();
  }

  // Theme Preference
  Future<void> saveThemePreference(String theme) async {
    await init();
    await _prefs?.setString(StorageKeys.themePreference, theme);
  }

  Future<String?> getThemePreference() async {
    await init();
    return _prefs?.getString(StorageKeys.themePreference);
  }

  // Language Preference
  Future<void> saveLanguage(String language) async {
    await init();
    await _prefs?.setString(StorageKeys.languagePreference, language);
  }

  Future<String?> getLanguage() async {
    await init();
    return _prefs?.getString(StorageKeys.languagePreference);
  }

  // Guest Mode
  Future<void> setGuestMode(bool isGuest) async {
    await init();
    await _prefs?.setBool(StorageKeys.isGuestMode, isGuest);
  }

  Future<bool> isGuestMode() async {
    await init();
    return _prefs?.getBool(StorageKeys.isGuestMode) ?? false;
  }

  // FCM Token
  Future<void> saveFcmToken(String token) async {
    await init();
    await _prefs?.setString(StorageKeys.fcmToken, token);
  }

  Future<String?> getFcmToken() async {
    await init();
    return _prefs?.getString(StorageKeys.fcmToken);
  }

  // Generic string storage (for notifications, etc.)
  Future<void> write(String key, String value) async {
    await init();
    await _prefs?.setString(key, value);
  }

  Future<String?> read(String key) async {
    await init();
    return _prefs?.getString(key);
  }

  // Persistent Saved Cars (Offline/Guest support)
  Future<void> saveSavedCars(List<CarModel> cars) async {
    try {
      final String jsonString = jsonEncode(
        cars.map((c) => c.toJson()).toList(),
      );
      await _secureStorage.write(key: 'saved_cars', value: jsonString);
    } catch (e) {
      debugPrint('Error saving cars locally: $e');
    }
  }

  Future<List<CarModel>> getSavedCars() async {
    try {
      final String? jsonString = await _secureStorage.read(key: 'saved_cars');
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CarModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error reading saved cars locally: $e');
      return [];
    }
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await init();
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
