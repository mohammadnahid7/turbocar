/// Chat Room Screen
/// Individual chat conversation with message input
/// Supports both existing conversations and pending (lazy) conversations
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/chat_room_data.dart';
import '../../../data/models/message_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  /// Conversation ID (null for pending conversations)
  final String? conversationId;

  /// Legacy: ConversationModel (for existing conversations from chat list)
  final ConversationModel? conversation;

  /// New: ChatRoomData (for pending conversations from car details)
  final ChatRoomData? chatRoomData;

  const ChatRoomScreen({
    super.key,
    this.conversationId,
    this.conversation,
    this.chatRoomData,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  int _lastMessageCount = 0; // Track message count to detect new messages

  // For pending conversations: track the created conversation ID
  String? _createdConversationId;
  bool _isCreatingConversation = false;

  /// Get the active conversation ID (either passed in or created later)
  String? get _activeConversationId =>
      _createdConversationId ?? widget.conversationId;

  /// Check if this is a pending (not yet created) conversation
  bool get _isPending => _activeConversationId == null;

  /// Get car data from either chatRoomData or conversation
  String? get _carId =>
      widget.chatRoomData?.carId ?? widget.conversation?.carId;
  String? get _carTitle =>
      widget.chatRoomData?.carTitle ?? widget.conversation?.carTitle;
  String? get _carImageUrl =>
      widget.chatRoomData?.carImageUrl ?? widget.conversation?.carImageUrl;
  double? get _carPrice =>
      widget.chatRoomData?.carPrice ?? widget.conversation?.carPrice;

  /// Get seller info from either chatRoomData or conversation
  String? get _sellerId => widget.chatRoomData?.sellerId;
  String? get _sellerName =>
      widget.chatRoomData?.sellerName ??
      widget.conversation?.participants.firstOrNull?.fullName;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark messages as seen when entering the chat room (only for existing conversations)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isPending) {
        _markMessagesSeen();
        _scrollToBottom();
        // Initialize message count for tracking new arrivals
        final state = ref.read(chatMessagesProvider(_activeConversationId!));
        _lastMessageCount = state.valueOrNull?.messages.length ?? 0;
      }
    });
  }

  void _markMessagesSeen() {
    final convId = _activeConversationId;
    if (convId == null) return; // Can't mark seen for pending conversation

    final repo = ref.read(chatRepositoryProvider);
    repo.sendSeen(convId);
    // Bug 3 fix: Update local conversation unread count to 0
    ref.read(conversationsProvider.notifier).markConversationAsRead(convId);
  }

  /// Bug 5: Scroll to bottom to show latest messages
  void _scrollToBottom() {
    // Use double addPostFrameCallback to ensure messages are laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Bug 1 fix: Check for new messages and mark them as seen
  /// This is called from build() via ref.listen - only fires while screen is active
  void _onNewMessageReceived(int newCount) {
    if (newCount > _lastMessageCount) {
      // New message arrived while we're viewing - mark as seen
      _markMessagesSeen();
      _scrollToBottom();
    }
    _lastMessageCount = newCount;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolling to top (only for existing conversations)
    final convId = _activeConversationId;
    if (convId == null) return;

    if (_scrollController.position.pixels <= 100) {
      ref.read(chatMessagesProvider(convId).notifier).loadMore();
    }
  }

  /// Send message - creates conversation first if pending
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // If pending, create conversation first
    if (_isPending) {
      if (_isCreatingConversation) return; // Prevent double creation

      final sellerId = _sellerId;
      if (sellerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Seller information missing')),
        );
        return;
      }

      setState(() => _isCreatingConversation = true);

      try {
        // Create conversation with car context
        final conversation = await ref
            .read(conversationsProvider.notifier)
            .startConversation([sellerId], carId: _carId, carTitle: _carTitle);

        // Store the created conversation ID
        setState(() {
          _createdConversationId = conversation.id;
          _isCreatingConversation = false;
        });

        // Now send the message to the created conversation
        ref
            .read(chatMessagesProvider(conversation.id).notifier)
            .sendMessage(text);
        _messageController.clear();
      } catch (e) {
        setState(() => _isCreatingConversation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start conversation: $e')),
          );
        }
        return;
      }
    } else {
      // Existing conversation - just send message
      ref
          .read(chatMessagesProvider(_activeConversationId!).notifier)
          .sendMessage(text);
      _messageController.clear();
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping(String value) {
    final convId = _activeConversationId;
    if (convId == null) return; // Can't send typing for pending conversation

    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      ref.read(chatMessagesProvider(convId).notifier).sendTypingIndicator();
    } else if (value.isEmpty) {
      _isTyping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    // Get seller name - from chatRoomData or conversation
    final sellerName = _sellerName ?? 'Chat';

    // For pending conversations, show empty state UI
    if (_isPending) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColorDark,
        appBar: AppBar(
          title: Text(sellerName),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 1,
        ),
        body: Column(
          children: [
            // Car context banner
            if (_carTitle != null) _buildCarContextBanner(),

            // Empty state for new conversation
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start a conversation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send a message to contact the seller',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Message input
            _buildMessageInput(),
          ],
        ),
      );
    }

    // Existing conversation - normal flow
    final chatState = ref.watch(chatMessagesProvider(_activeConversationId!));

    // Bug 1 fix: Listen for new messages and mark as seen while screen is active
    ref.listen<AsyncValue<ChatRoomState>>(
      chatMessagesProvider(_activeConversationId!),
      (prev, next) {
        final prevCount = prev?.valueOrNull?.messages.length ?? 0;
        final newCount = next.valueOrNull?.messages.length ?? 0;
        if (newCount > prevCount && prevCount > 0) {
          _onNewMessageReceived(newCount);
        }
      },
    );

    // Get seller name from other participant (for existing conversations)
    final otherParticipant = widget.conversation?.getOtherParticipant(
      currentUserId,
    );
    final displayName = otherParticipant?.fullName ?? sellerName;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Theme.of(context).primaryColorDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Car context banner (use _carTitle getter to get from either source)
          if (_carTitle != null) _buildCarContextBanner(),

          // Messages list
          Expanded(
            child: chatState.when(
              data: (state) => _buildMessageList(state, currentUserId),
              loading: () =>
                  const LoadingIndicator(message: 'Loading messages...'),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),

          // Typing indicator
          if (chatState.valueOrNull?.isTyping == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 40, child: _buildTypingIndicator()),
                  const SizedBox(width: 8),
                  Text(
                    'typing...',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatRoomState state, String currentUserId) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final msgIndex = state.isLoading ? index - 1 : index;
        final message = state.messages[msgIndex];
        final isMe = message.isFromMe(currentUserId);

        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message content
            if (message.messageType == 'image' && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.mediaUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),

            const SizedBox(height: 4),

            // Time and status indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status, isMe),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build status icon based on message status
  Widget _buildStatusIcon(String status, bool isMe) {
    switch (status) {
      case 'seen':
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlueAccent,
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withValues(alpha: 0.7),
        );
      case 'sent':
      default:
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.white.withValues(alpha: 0.7),
        );
    }
  }

  /// Build car context banner using getters (works for both existing and pending conversations)
  Widget _buildCarContextBanner() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Car image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _carImageUrl != null && _carImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _carImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.directions_car,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.directions_car,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Icon(
                      Icons.directions_car,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Car info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _carTitle ?? 'Car',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_carPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '\$${_carPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // View button
          TextButton(
            onPressed: () {
              if (_carId != null) {
                // Navigate to car details
                Navigator.pushNamed(context, '/car-details', arguments: _carId);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Implement media picker
            },
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _onTyping,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
