/// Notification Card Widget
/// Displays a price change notification with car info
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = notification.data ?? {};

    // Extract price info from data
    final oldPrice = double.tryParse(data['old_price']?.toString() ?? '0') ?? 0;
    final newPrice = double.tryParse(data['new_price']?.toString() ?? '0') ?? 0;

    // Extract car image - handle both single string and array formats
    String? carImageUrl = data['car_image'] as String?;

    if (carImageUrl == null && data['images'] != null) {
      final images = data['images'];
      if (images is List && images.isNotEmpty) {
        carImageUrl = images.first.toString();
      } else if (images is String) {
        // Try to parse JSON array string if it comes as string
        try {
          if (images.startsWith('[')) {
            // Simple parsing for JSON array string
            final clean = images
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll('"', '');
            final parts = clean.split(',');
            if (parts.isNotEmpty) {
              carImageUrl = parts.first.trim();
            }
          } else {
            // Assume comma separated or just a single url string
            carImageUrl = images.split(',').first.trim();
          }
        } catch (_) {
          carImageUrl = images;
        }
      }
    }

    final isPriceDecrease = newPrice < oldPrice;

    // Text style based on read status
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
    );

    return Card(
      color: notification.isRead
          ? Theme.of(context).colorScheme.surface
          : Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 60,
                  child: carImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: carImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.directions_car, size: 30),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.directions_car, size: 30),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.directions_car,
                            size: 30,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price change info
                    if (notification.type == 'price_change') ...[
                      Row(
                        children: [
                          Icon(
                            isPriceDecrease
                                ? Icons.trending_down
                                : Icons.trending_up,
                            size: 16,
                            color: isPriceDecrease ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPriceDecrease
                                ? 'Price dropped'
                                : 'Price increased',
                            style: bodyStyle?.copyWith(
                              color: isPriceDecrease
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '\$${oldPrice.toStringAsFixed(0)}',
                            style: bodyStyle?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${newPrice.toStringAsFixed(0)}',
                            style: bodyStyle?.copyWith(
                              color: isPriceDecrease
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        notification.message,
                        style: bodyStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Timestamp
              // const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Unread indicator
              // if (!notification.isRead)
              //   Container(
              //     width: 10,
              //     height: 10,
              //     margin: const EdgeInsets.only(left: 8),
              //     decoration: BoxDecoration(
              //       color: theme.colorScheme.primary,
              //       shape: BoxShape.circle,
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
