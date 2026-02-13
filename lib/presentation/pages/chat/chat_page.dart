/// Chat Page (Conversation List)
/// Displays list of user's chat conversations with role-based filtering
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
import '../../widgets/common/role_badge.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Connect to WebSocket when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
      // Acknowledge all current chats - badge becomes 0
      // Only NEW chats with unread after this will show in badge
      _acknowledgeAllChats();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// Mark all current conversations as "acknowledged" so badge shows 0
  /// New messages in these chats won't show in badge until user leaves
  void _acknowledgeAllChats() {
    final conversations = ref.read(conversationsProvider).valueOrNull ?? [];
    final allIds = conversations.map((c) => c.id).toSet();
    ref.read(acknowledgedChatsProvider.notifier).state = allIds;
  }

  Future<void> _connectWebSocket() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final connectionManager = ref.read(chatConnectionManagerProvider);
    // Use centralized WebSocket URL from ApiConstants

    try {
      print('Nahid: Connecting to WebSocket...');
      await connectionManager.connectWithStoredToken(ApiConstants.wsBaseUrl);
    } catch (e) {
      // Connection error handled by SocketService reconnection logic
      debugPrint('WebSocket connection error: $e');
    }
  }

  /// Filter conversations based on selected tab and current user's role
  List<ConversationModel> _getFilteredConversations(
    List<ConversationModel> allConversations,
    String currentUserId,
  ) {
    final tabIndex = _tabController.index;

    if (tabIndex == 0) {
      // All tab - show all conversations
      return allConversations;
    } else if (tabIndex == 1) {
      // buying tab - show only conversations where user is buying
      return allConversations
          .where((c) => c.getUserRole(currentUserId) == 'buying')
          .toList();
    } else {
      // Seller tab - show only conversations where user is seller
      return allConversations
          .where((c) => c.getUserRole(currentUserId) == 'selling')
          .toList();
    }
  }

  /// Get counts for each tab
  Map<String, int> _getCounts(
    List<ConversationModel> allConversations,
    String currentUserId,
  ) {
    int buyingCount = 0;
    int sellingCount = 0;

    for (final conv in allConversations) {
      if (conv.getUserRole(currentUserId) == 'buying') {
        buyingCount++;
      } else {
        sellingCount++;
      }
    }

    return {
      'all': allConversations.length,
      'buying': buyingCount,
      'selling': sellingCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Watch stream providers to keep them active for real-time updates
    // These providers handle unread count and conversation list updates
    ref.watch(unreadUpdateHandlerProvider);
    ref.watch(conversationUpdateHandlerProvider);

    // If guest or not authenticated, show login prompt
    if (authState.isGuest || !authState.isAuthenticated) {
      return _buildLoginPrompt(context);
    }

    // Authenticated user - show conversation list with tabs
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.chats, isMainNavPage: true),
      body: _buildConversationListWithTabs(),
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

  Widget _buildConversationListWithTabs() {
    final conversationsAsync = ref.watch(conversationsProvider);
    final connectionState = ref.watch(connectionStateProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    return Column(
      children: [
        // Connection status indicator
        connectionState.when(
          data: (state) => _buildConnectionBanner(state),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Tab bar
        conversationsAsync.when(
          data: (conversations) {
            final counts = _getCounts(conversations, currentUserId);
            return _buildTabBar(counts);
          },
          loading: () => _buildTabBar({'all': 0, 'buying': 0, 'selling': 0}),
          error: (_, __) => _buildTabBar({'all': 0, 'buying': 0, 'selling': 0}),
        ),

        // Conversation list
        Expanded(
          child: conversationsAsync.when(
            data: (conversations) {
              final filteredConversations = _getFilteredConversations(
                conversations,
                currentUserId,
              );

              if (filteredConversations.isEmpty) {
                return _buildEmptyStateForTab();
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    return _buildConversationTile(
                      filteredConversations[index],
                      currentUserId,
                    );
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
                  const Text('Failed to load conversations'),
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

  Widget _buildTabBar(Map<String, int> counts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'All (${counts['all']})'),
          Tab(text: 'Buying (${counts['buying']})'),
          Tab(text: 'Selling (${counts['selling']})'),
        ],
      ),
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

  Widget _buildEmptyStateForTab() {
    String message;
    switch (_tabController.index) {
      case 1:
        message = 'No buying conversations yet';
      case 2:
        message = 'No selling conversations yet';
      default:
        message = 'No conversations yet';
    }

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
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _tabController.index == 1
                  ? 'Start a conversation by messaging a car seller'
                  : _tabController.index == 2
                  ? 'Post a car and wait for buyers to contact you'
                  : 'Start a conversation by messaging a car seller',
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

  Widget _buildConversationTile(
    ConversationModel conversation,
    String currentUserId,
  ) {
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    final lastMessage = conversation.lastMessage;
    final role = conversation.getUserRole(currentUserId);

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
      title: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  // Show car title if available, otherwise show participant name
                  conversation.carTitle ?? otherParticipant?.fullName ?? 'Chat',
                  style: TextStyle(
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
                RoleBadge(role: role),
              ],
            ),
          ),
        ],
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
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w700
                    : FontWeight.w400,
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
        context.push('/chat/${conversation.id}', extra: conversation);
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
