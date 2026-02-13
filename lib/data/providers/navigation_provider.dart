/// Navigation Provider
/// Manages bottom navigation bar state for instant page switching
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation State
class NavigationState {
  final int currentIndex;

  NavigationState({this.currentIndex = 0});

  NavigationState copyWith({int? currentIndex}) {
    return NavigationState(currentIndex: currentIndex ?? this.currentIndex);
  }
}

// Navigation Notifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState());

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

// Navigation Provider
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier();
    });
