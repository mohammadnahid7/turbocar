/// Bottom Navigation Bar
/// Main navigation bar with 5 tabs - instant navigation using state provider
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turbo_car/core/theme/app_colors.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../providers/chat_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Add margin at bottom for floating effect - content shows through
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Container - Home & Saved
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    ref,
                    Icons.home_filled,
                    Icons.home_outlined,
                    'Home',
                    0,
                    currentIndex,
                  ),
                  _buildNavItem(
                    context,
                    ref,
                    Icons.bookmark,
                    Icons.bookmark_outline,
                    'Saved',
                    1,
                    currentIndex,
                  ),
                ],
              ),
            ),
          ),
          // Middle Container - Center + Button
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(65),
                topRight: Radius.circular(65),
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: GestureDetector(
                  onTap: () =>
                      ref.read(navigationProvider.notifier).setIndex(2),
                  child: Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        width: 6,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right Container - Chat & Profile
          Expanded(
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChatNavItem(context, ref, currentIndex),
                  _buildNavItem(
                    context,
                    ref,
                    Icons.person,
                    Icons.person_outline,
                    'Profile',
                    4,
                    currentIndex,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build chat nav item with unread badge
  Widget _buildChatNavItem(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    final bool selected = currentIndex == 3;
    final Color inactive = const Color.fromARGB(109, 255, 255, 255);
    final Color active = Colors.white;
    // Badge counts unique chats with unread messages (not total messages)
    final unreadChatsCount = ref.watch(unreadChatsCountProvider);

    return InkWell(
      onTap: () {
        ref.read(navigationProvider.notifier).setIndex(3);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            // Hide badge when on chat page OR when no unread chats
            isLabelVisible: unreadChatsCount > 0 && currentIndex != 3,
            label: Text(
              unreadChatsCount > 99 ? '99+' : '$unreadChatsCount',
              style: const TextStyle(fontSize: 10),
            ),
            child: Icon(
              selected ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: 22,
              color: selected ? active : inactive,
            ),
          ),
          Text(
            'Chat',
            style: TextStyle(color: selected ? active : inactive, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    IconData selectedIcon,
    IconData normalIcon,
    String label,
    int index,
    int currentIndex,
  ) {
    final bool selected = currentIndex == index;
    final Color inactive = const Color.fromARGB(109, 255, 255, 255);
    final Color active = Colors.white;
    return InkWell(
      onTap: () {
        // Instant navigation - no routing, just state change
        ref.read(navigationProvider.notifier).setIndex(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? selectedIcon : normalIcon,
            size: 22,
            color: selected ? active : inactive,
          ),
          Text(
            label,
            style: TextStyle(color: selected ? active : inactive, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
