/// Main Navigation Page
/// Container for bottom navigation with IndexedStack for instant page switching
/// All pages are kept in memory for instant navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/navigation_provider.dart';
import '../widgets/common/bottom_nav_bar.dart';
import 'home/home_page.dart';
import 'saved/saved_page.dart';
import 'post/post_page.dart';
import 'chat/chat_page.dart';
import 'profile/profile_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void initState() {
    super.initState();
    // Initialize navigation to home (index 0) on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).setIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationState = ref.watch(navigationProvider);

    // IndexedStack keeps all pages in memory for instant switching
    // Only the page at currentIndex is visible, but all are built
    return Scaffold(
      extendBody: true, // Content extends behind bottom nav bar
      body: IndexedStack(
        index: navigationState.currentIndex,
        children: const [
          HomePage(),
          SavedPage(),
          PostPage(),
          ChatPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
