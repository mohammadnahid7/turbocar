/// User Repository
/// Handles user-related operations
library;

import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserRepository {
  final AuthService _authService;

  UserRepository(this._authService);

  // Fetch profile
  Future<UserModel> fetchProfile() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        return user;
      }
      throw Exception("User not found");
    } catch (e) {
      rethrow;
    }
  }

  // Update profile
  Future<UserModel> updateProfile(Map<String, dynamic> userData) async {
    try {
      return await _authService.updateProfile(userData);
    } catch (e) {
      rethrow;
    }
  }
}
