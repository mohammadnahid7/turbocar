/// Seller Info Card Widget
/// Displays seller profile image and name on car details page
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A card widget displaying seller information with avatar and name
class SellerInfoCard extends StatelessWidget {
  final String? sellerName;
  final String? sellerProfilePhotoUrl;
  final VoidCallback? onTap;

  const SellerInfoCard({
    super.key,
    this.sellerName,
    this.sellerProfilePhotoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = sellerName ?? 'Unknown Seller';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              // Seller Avatar
              _buildAvatar(context, displayName),
              const SizedBox(width: 12),

              // Seller Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'Seller',
                    //   style: theme.textTheme.bodySmall?.copyWith(
                    //     color: theme.colorScheme.onSurface.withValues(
                    //       alpha: 0.6,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow icon if tappable
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the avatar with profile photo or placeholder
  Widget _buildAvatar(BuildContext context, String displayName) {
    if (sellerProfilePhotoUrl != null && sellerProfilePhotoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: sellerProfilePhotoUrl!,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: 20, backgroundImage: imageProvider),
        placeholder: (context, url) =>
            _buildPlaceholderAvatar(context, displayName),
        errorWidget: (context, url, error) =>
            _buildPlaceholderAvatar(context, displayName),
      );
    }

    return _buildPlaceholderAvatar(context, displayName);
  }

  /// Build a placeholder avatar with the first letter of the name
  Widget _buildPlaceholderAvatar(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
