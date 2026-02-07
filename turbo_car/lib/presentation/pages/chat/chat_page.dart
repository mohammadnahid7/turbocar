/// Chat Page (Conversation List)
/// Displays list of user's chat conversations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/services/socket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/router/route_names.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });
  }

  Future<void> _connectWebSocket() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final connectionManager = ref.read(chatConnectionManagerProvider);
    // Use centralized WebSocket URL from ApiConstants

    try {
      await connectionManager.connectWithStoredToken(ApiConstants.wsBaseUrl);
    } catch (e) {
      // Connection error handled by SocketService reconnection logic
      debugPrint('WebSocket connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // If guest or not authenticated, show login prompt
    if (authState.isGuest || !authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    // Authenticated user - show conversation list
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.chats, isMainNavPage: true),
      body: _buildConversationList(),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.chats, isMainNavPage: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                StringConstants.pleaseLoginToChat,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: StringConstants.loginOrSignup,
                onPressed: () => context.push(RouteNames.login),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    final conversationsAsync = ref.watch(conversationsProvider);
    final connectionState = ref.watch(connectionStateProvider);

    return Column(
      children: [
        // Connection status indicator
        connectionState.when(
          data: (state) => _buildConnectionBanner(state),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Conversation list
        Expanded(
          child: conversationsAsync.when(
            data: (conversations) {
              if (conversations.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    return _buildConversationTile(conversations[index]);
                  },
                ),
              );
            },
            loading: () =>
                const LoadingIndicator(message: 'Loading conversations...'),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load conversations'),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Retry',
                    onPressed: () =>
                        ref.read(conversationsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionBanner(SocketConnectionState state) {
    if (state == SocketConnectionState.connected) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    String message;
    IconData icon;

    switch (state) {
      case SocketConnectionState.connecting:
        bgColor = Colors.orange;
        message = 'Connecting...';
        icon = Icons.sync;
      case SocketConnectionState.reconnecting:
        bgColor = Colors.orange;
        message = 'Reconnecting...';
        icon = Icons.sync;
      case SocketConnectionState.disconnected:
        bgColor = Colors.red;
        message = 'Offline - Messages may be delayed';
        icon = Icons.cloud_off;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by messaging a car seller',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id ?? '';
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    final lastMessage = conversation.lastMessage;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherParticipant?.avatarUrl != null
            ? NetworkImage(otherParticipant!.avatarUrl!)
            : null,
        child: otherParticipant?.avatarUrl == null
            ? Text(
                (otherParticipant?.fullName ?? '?').isNotEmpty
                    ? (otherParticipant!.fullName ?? '?')[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        // Show car title if available, otherwise show participant name
        conversation.carTitle ?? otherParticipant?.fullName ?? 'Chat',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show seller name when car title is displayed
          if (conversation.carTitle != null &&
              otherParticipant?.fullName != null)
            Text(
              'with ${otherParticipant!.fullName}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          // Show last message or placeholder
          if (lastMessage != null)
            Text(
              lastMessage.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          else
            const Text('No messages yet'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessage != null)
            Text(
              _formatTime(lastMessage.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        context.push('/chat/${conversation.id}');
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
