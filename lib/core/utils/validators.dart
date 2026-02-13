/// Validators
/// Contains validation functions for form fields
library;

import '../constants/app_constants.dart';
import '../constants/string_constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return StringConstants.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return StringConstants.emailInvalid;
    }
    return null;
  }

  // Password validation - returns map with requirements status
  static Map<String, bool> validatePasswordRequirements(String password) {
    return {
      'minLength': password.length >= AppConstants.minPasswordLength,
      'hasUppercase': AppConstants.requireUppercase
          ? password.contains(RegExp(r'[A-Z]'))
          : true,
      'hasLowercase': AppConstants.requireLowercase
          ? password.contains(RegExp(r'[a-z]'))
          : true,
      'hasNumber': AppConstants.requireNumbers
          ? password.contains(RegExp(r'[0-9]'))
          : true,
      'hasSpecialChar': AppConstants.requireSpecialChars
          ? password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))
          : true,
    };
  }

  // Password validation - returns error message
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return StringConstants.passwordRequired;
    }
    if (password.length < AppConstants.minPasswordLength) {
      return StringConstants.passwordTooShort;
    }

    final requirements = validatePasswordRequirements(password);
    if (!requirements['minLength']!) {
      return StringConstants.passwordTooShort;
    }
    if (!requirements['hasUppercase']!) {
      return StringConstants.passwordMustContainUppercase;
    }
    if (!requirements['hasLowercase']!) {
      return StringConstants.passwordMustContainLowercase;
    }
    if (!requirements['hasNumber']!) {
      return StringConstants.passwordMustContainNumber;
    }
    if (!requirements['hasSpecialChar']!) {
      return StringConstants.passwordMustContainSpecialChar;
    }

    return null;
  }

  // Phone validation
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return StringConstants.phoneRequired;
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''))) {
      return StringConstants.phoneInvalid;
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Date of birth validation
  static String? validateDateOfBirth(DateTime? dob) {
    if (dob == null) {
      return StringConstants.dateOfBirthRequired;
    }
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    if (age < AppConstants.minUserAge) {
      return StringConstants.ageTooYoung;
    }
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return StringConstants.passwordRequired;
    }
    if (password != confirmPassword) {
      return StringConstants.passwordsDoNotMatch;
    }
    return null;
  }

  // Check if input is valid email OR phone
  static bool isValidEmailOrPhone(String input) {
    if (input.isEmpty) return false;

    // Check email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (emailRegex.hasMatch(input)) return true;

    // Check phone format (10-15 digits)
    final cleanPhone = input.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (phoneRegex.hasMatch(cleanPhone)) return true;

    return false;
  }

  // Validate email or phone field
  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone is required';
    }
    if (!isValidEmailOrPhone(value)) {
      return 'Please enter a valid email or phone number';
    }
    return null;
  }
}
