/// Auth Router Notifier
/// Provides a ChangeNotifier for go_router's refreshListenable
/// This ensures the router only rebuilds when authentication ACTUALLY changes
/// (not on loading state or error state changes)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';

/// A ChangeNotifier that only notifies when authentication status changes
/// This prevents router rebuilds during loading/error states
class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _wasAuthenticated = false;
  bool _wasGuest = false;
  bool _wasInitialized = false;

  AuthRouterNotifier(this._ref) {
    // Listen to auth changes but only notify router when auth STATUS changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Only notify if the authentication/guest/initialized status changed
      // NOT if loading or error changed
      final authChanged = _wasAuthenticated != next.isAuthenticated;
      final guestChanged = _wasGuest != next.isGuest;
      final initChanged = _wasInitialized != next.isInitialized;

      if (authChanged || guestChanged || initChanged) {
        _wasAuthenticated = next.isAuthenticated;
        _wasGuest = next.isGuest;
        _wasInitialized = next.isInitialized;
        notifyListeners();
      }
    });
  }

  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;
  bool get isGuest => _ref.read(authProvider).isGuest;
  bool get isInitialized => _ref.read(authProvider).isInitialized;
}

/// Provider for the auth router notifier
final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});
