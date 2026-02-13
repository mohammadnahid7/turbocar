/// Custom App Bar
/// Reusable app bar widget with smart back button behavior
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turbo_car/presentation/widgets/common/custom_button.dart';
import '../../../data/providers/navigation_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool isMainNavPage; // If true, back button navigates to home

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.isMainNavPage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      child: AppBar(
        backgroundColor: Theme.of(context).primaryColorDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CustomButton.icon(
          backgroundColor: Theme.of(context).cardColor,
          icon: Icons.arrow_back,
          onPressed: () {
            if (isMainNavPage) {
              // Navigate to home when on main nav pages
              ref.read(navigationProvider.notifier).setIndex(0);
            } else {
              // Normal back navigation for nested pages
              Navigator.pop(context);
            }
          },
        ),
        title: Text(title),
        centerTitle: true,
        actions: actions ?? [],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);
}
