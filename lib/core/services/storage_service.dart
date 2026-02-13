/// Storage Service
/// Handles secure storage and shared preferences operations
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

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

  Future<String?> getUserData() async {
    return await _secureStorage.read(key: StorageKeys.userData);
  }

  Future<void> clearUserData() async {
    await _secureStorage.delete(key: StorageKeys.userData);
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

  // Clear all data (logout)
  Future<void> clearAll() async {
    await init();
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
