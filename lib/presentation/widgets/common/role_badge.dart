/// Role Badge Widget
/// Displays buying/selling badge in chat list
library;

import 'package:flutter/material.dart';
import 'package:turbo_car/core/theme/app_colors.dart';

/// A badge widget showing the user's role in a conversation
/// Either "buying" or "selling" depending on relationship to the car
class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isSeller = role.toLowerCase() == 'selling';

    // Define colors based on role
    final backgroundColor = isSeller
        ? AppColors.lightWarning.withValues(alpha: 0.2)
        : AppColors.lightSuccess.withValues(alpha: 0.2);

    final textColor = isSeller
        ? const Color.fromARGB(255, 228, 171, 0)
        : AppColors.lightSuccess;

    final displayText = isSeller ? 'Selling' : 'Buying';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
