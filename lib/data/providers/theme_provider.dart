/// Theme Provider
/// State management for theme mode using Riverpod
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Theme Provider - Override this in providers.dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  throw UnimplementedError(
    'ThemeProvider must be overridden in providers.dart',
  );
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeNotifier(this._storageService) : super(ThemeMode.light) {
    loadThemePreference();
  }

  // Load theme preference from storage
  Future<void> loadThemePreference() async {
    try {
      final preference = await _storageService.getThemePreference();
      if (preference == 'light') {
        state = ThemeMode.light;
      } else if (preference == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.light;
      }
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await _storageService.saveThemePreference('dark');
    } else {
      state = ThemeMode.light;
      await _storageService.saveThemePreference('light');
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String preference = 'light';
    if (mode == ThemeMode.light) {
      preference = 'light';
    } else if (mode == ThemeMode.dark) {
      preference = 'dark';
    }
    await _storageService.saveThemePreference(preference);
  }
}
