/// App Colors
/// Defines all color constants for light and dark themes
library;

import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFDAAB2D);
  static const Color lightSecondary = Color(0xFFA57A03);
  static const Color lightAccent = Color(0xFF400218);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightError = Color(0xFFB00020);
  static const Color lightSuccess = Color(0xFF4CAF50);
  static const Color lightWarning = Color(0xFFFFC107);
  static const Color lightTextPrimary = Color(0xFF08131A);
  static const Color lightTextSecondary = Color(0xFF2A2A2A);
  static const Color lightDivider = Color(0xFFEBEBEB);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF5A189A);
  static const Color darkSecondary = Color(0xFF31173A);
  static const Color darkAccent = Color(0xFF341D3D);
  static const Color darkBackground = Color(0xFF210F29);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFD3AFF6);
  static const Color darkDivider = Color(0xFF424242);

  // Common Colors (same for both themes)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}
