/// Notification Page
/// Displays list of notifications with price alerts
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/string_constants.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/notification/notification_card.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(
        title: StringConstants.notificationPageTitle,
        actions: [
          if (notificationState.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  ref.read(notificationListProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearConfirmation(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20),
                      SizedBox(width: 12),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(context, ref, notificationState, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationListState state,
    ThemeData theme,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Could add refresh logic here if needed
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => _onNotificationTap(
              context,
              ref,
              notification.id,
              notification.data,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Price alerts for your saved cars will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
    Map<String, dynamic>? data,
  ) {
    // Mark as read
    ref.read(notificationListProvider.notifier).markAsRead(notificationId);

    // Navigate based on notification type
    final type = data?['type'] as String?;
    final carId = data?['car_id'] as String?;

    if (type == 'price_change' && carId != null) {
      context.push('/post/$carId');
    } else if (type == 'chat_message') {
      final conversationId = data?['conversation_id'] as String?;
      if (conversationId != null) {
        context.push('/chat/$conversationId');
      }
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationListProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
