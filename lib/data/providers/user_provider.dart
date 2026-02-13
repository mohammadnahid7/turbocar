/// User Provider
/// State management for user profile using Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

// User State
class UserState {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  UserState({this.isLoading = false, this.user, this.error});

  UserState copyWith({bool? isLoading, UserModel? user, String? error}) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

// User Notifier
class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _userRepository;

  UserNotifier(this._userRepository) : super(UserState());

  // Fetch user profile
  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _userRepository.fetchProfile();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _userRepository.updateProfile(userData);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// User Provider - Override this in providers.dart
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  throw UnimplementedError('UserProvider must be overridden in providers.dart');
});
