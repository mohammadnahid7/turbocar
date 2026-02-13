/// Extensions
/// Contains extension methods for common types
library;

import 'package:flutter/material.dart';
import 'helpers.dart';

// String Extensions
extension StringExtensions on String {
  // Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Check if valid email
  bool isValidEmail() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  // Check if valid phone
  bool isValidPhone() {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(replaceAll(RegExp(r'[\s-]'), ''));
  }
}

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  // Format to string
  String toFormattedString() {
    return Helpers.formatDate(this);
  }

  // Check if today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // Check if yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // Get relative time string (Today, Yesterday, or formatted date)
  String getRelativeTimeString() {
    if (isToday()) {
      return 'Today';
    } else if (isYesterday()) {
      return 'Yesterday';
    } else {
      return toFormattedString();
    }
  }
}

// BuildContext Extensions
extension BuildContextExtensions on BuildContext {
  // Show success snackbar
  void showSuccessSnackBar(String message) {
    Helpers.showSnackBar(
      this,
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // Show error snackbar
  void showErrorSnackBar(String message) {
    Helpers.showSnackBar(
      this,
      message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  // Show loading dialog
  void showLoadingDialog() {
    Helpers.showLoadingDialog(this);
  }

  // Hide dialog
  void hideDialog() {
    Navigator.of(this, rootNavigator: true).pop();
  }
}
