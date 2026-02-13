/// Chat Provider
/// Riverpod state management for chat functionality
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/socket_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/providers/providers.dart'; // Contains storageServiceProvider

// --- Service Providers ---

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final chatServiceProvider = Provider<ChatService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatService(dioClient.dio);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ChatRepository(chatService: chatService, socketService: socketService);
});

// --- State Providers ---

/// Connection state stream
final connectionStateProvider = StreamProvider<SocketConnectionState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.connectionStateStream;
});

/// Incoming message stream
final incomingMessageProvider = StreamProvider<WSMessage>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.messageStream;
});

/// Badge shows count of conversations with unread messages
/// Only counts NEW conversations that got unread after user left chat page
///
/// Flow:
/// 1. User enters chat page → acknowledgedChatsProvider = all conversation IDs
/// 2. User leaves → new messages arrive → badge = count of chats with unread NOT in acknowledged
/// 3. User re-enters chat page → reset acknowledged
final acknowledgedChatsProvider = StateProvider<Set<String>>((ref) => {});

/// Computed: Count conversations with unread messages that haven't been acknowledged
/// Returns 0 when user is on chat page (handled in UI via currentIndex)
final unreadChatsCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
  final acknowledged = ref.watch(acknowledgedChatsProvider);

  // Count conversations with unread > 0 that user hasn't acknowledged
  return conversations
      .where((c) => c.unreadCount > 0 && !acknowledged.contains(c.id))
      .length;
});

/// Legacy: Keep for backend event handling but don't use for badge
final totalUnreadProvider = StateProvider<int>((ref) => 0);

/// Handles incoming unread:update events (kept for compatibility)
final unreadUpdateHandlerProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.messageStream.where((msg) => msg.type == 'unread:update').map((
    msg,
  ) {
    final count = int.tryParse(msg.content ?? '0') ?? 0;
    ref.read(totalUnreadProvider.notifier).state = count;
  });
});

/// Handles incoming conversation:updated events to refresh chat list in real-time
/// This provider should be watched from a high-level widget to stay active
final conversationUpdateHandlerProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.messageStream
      .where((msg) => msg.type == 'conversation:updated')
      .map((msg) {
        // Trigger a refresh of conversation list when any conversation is updated
        // Use a debounce to avoid excessive refreshes on rapid messages
        ref.read(conversationsProvider.notifier).handleConversationUpdate(msg);
      });
});

// --- Conversation Providers ---

/// List of all conversations
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
      ConversationsNotifier.new,
    );

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
  // Deduplication: Track last processed message per conversation to prevent double updates
  final Map<String, String> _lastProcessedMessage = {};

  @override
  Future<List<ConversationModel>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    return repo.getConversations();
  }

  /// Refresh conversations
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(chatRepositoryProvider);
      return repo.getConversations();
    });
  }

  /// Start a new conversation
  Future<ConversationModel> startConversation(
    List<String> participantIds, {
    String? carId,
    String? carTitle,
    Map<String, dynamic>? context,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversation = await repo.startConversation(
      participantIds,
      carId: carId,
      carTitle: carTitle,
      context: context,
    );
    await refresh();
    return conversation;
  }

  /// Handle real-time conversation update from WebSocket
  /// Updates local state immediately, then refreshes from server
  void handleConversationUpdate(WSMessage msg) {
    // Deduplication: Create unique key from conversation+timestamp+content
    final messageKey = '${msg.conversationId}_${msg.timestamp}_${msg.content}';
    if (_lastProcessedMessage[msg.conversationId] == messageKey) {
      // Skip duplicate event
      return;
    }
    _lastProcessedMessage[msg.conversationId] = messageKey;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Get current user ID to check if message is from someone else
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id ?? '';
    final isFromOtherUser =
        msg.senderId != null && msg.senderId != currentUserId;

    // Find the updated conversation
    final index = currentState.indexWhere((c) => c.id == msg.conversationId);

    if (index >= 0) {
      // Create updated last message
      final updatedLastMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: msg.conversationId,
        senderId: msg.senderId ?? '',
        content: msg.content ?? '',
        messageType: msg.messageType ?? 'text',
        createdAt: msg.timestamp ?? DateTime.now().toIso8601String(),
      );

      // Bug 3 fix: Increment unread count if message is from other user
      final currentUnread = currentState[index].unreadCount;
      print('Nahid currentUnread: $currentUnread');
      final newUnreadCount = isFromOtherUser
          ? currentUnread + 1
          : currentUnread;

      // Update conversation with new last message and move to top
      final updatedConversation = currentState[index].copyWith(
        lastMessage: updatedLastMessage,
        updatedAt: msg.timestamp ?? DateTime.now().toIso8601String(),
        unreadCount: newUnreadCount,
      );

      // Remove from current position and add to top
      final newList = [...currentState];
      newList.removeAt(index);
      newList.insert(0, updatedConversation);

      state = AsyncData(newList);
    } else {
      // New conversation - refresh from server to get full details
      refresh();
    }
  }

  /// Bug 3 fix: Mark a conversation as read (set unread count to 0)
  /// Called when user enters a chat room and sees messages
  void markConversationAsRead(String conversationId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final index = currentState.indexWhere((c) => c.id == conversationId);
    if (index >= 0 && currentState[index].unreadCount > 0) {
      final updatedConversation = currentState[index].copyWith(unreadCount: 0);
      final newList = [...currentState];
      newList[index] = updatedConversation;
      state = AsyncData(newList);
    }
  }
}

// --- Chat Room Providers ---

/// Messages for a specific conversation
final chatMessagesProvider =
    AsyncNotifierProviderFamily<ChatMessagesNotifier, ChatRoomState, String>(
      ChatMessagesNotifier.new,
    );

class ChatRoomState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final bool isTyping; // Other user is typing

  ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.isTyping = false,
  });

  ChatRoomState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    bool? isTyping,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatMessagesNotifier extends FamilyAsyncNotifier<ChatRoomState, String> {
  StreamSubscription? _messageSubscription;

  @override
  Future<ChatRoomState> build(String conversationId) async {
    final repo = ref.watch(chatRepositoryProvider);

    // Load initial messages
    final response = await repo.getMessages(conversationId);

    // Subscribe to incoming messages for this conversation
    _messageSubscription?.cancel();
    _messageSubscription = repo.messageStream
        .where((msg) => msg.conversationId == conversationId)
        .listen(_handleIncomingMessage);

    ref.onDispose(() => _messageSubscription?.cancel());

    return ChatRoomState(
      messages: response.messages.reversed.toList(), // Oldest first
      hasMore: response.hasMore,
      currentPage: 1,
    );
  }

  void _handleIncomingMessage(WSMessage wsMessage) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (wsMessage.type == 'message') {
      // Add new message to the list
      final newMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        conversationId: wsMessage.conversationId,
        senderId: wsMessage.senderId ?? '',
        content: wsMessage.content ?? '',
        messageType: wsMessage.messageType ?? 'text',
        mediaUrl: wsMessage.mediaUrl,
        status: 'delivered', // Received means delivered
        createdAt: wsMessage.timestamp ?? DateTime.now().toIso8601String(),
      );

      state = AsyncData(
        currentState.copyWith(messages: [...currentState.messages, newMessage]),
      );

      // Send delivered acknowledgment
      final repo = ref.read(chatRepositoryProvider);
      repo.sendDelivered(wsMessage.conversationId, newMessage.id);
      // NOTE: sendSeen handled by ChatRoomScreen lifecycle, not here
    } else if (wsMessage.type == 'typing') {
      // Show typing indicator
      state = AsyncData(currentState.copyWith(isTyping: true));

      // Hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.hasValue) {
          state = AsyncData(state.value!.copyWith(isTyping: false));
        }
      });
    } else if (wsMessage.type == 'read_receipt' ||
        wsMessage.type == 'messages:seen') {
      // Update status to seen for my messages
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.senderId != wsMessage.content && msg.status != 'seen') {
          return msg.copyWith(status: 'seen', isRead: true);
        }
        return msg;
      }).toList();

      state = AsyncData(currentState.copyWith(messages: updatedMessages));
    } else if (wsMessage.type == 'message:delivered') {
      // Update status to delivered for the specific message
      final messageId = wsMessage.content;
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.id == messageId && msg.status == 'sent') {
          return msg.copyWith(status: 'delivered');
        }
        return msg;
      }).toList();

      state = AsyncData(currentState.copyWith(messages: updatedMessages));
    }
  }

  /// Send a text message
  void sendMessage(String content) {
    final repo = ref.read(chatRepositoryProvider);
    repo.sendTextMessage(arg, content);

    // Optimistically add message to list
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? '';

      final optimisticMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: arg,
        senderId: userId,
        content: content,
        messageType: 'text',
        createdAt: DateTime.now().toIso8601String(),
      );

      state = AsyncData(
        currentState.copyWith(
          messages: [...currentState.messages, optimisticMessage],
        ),
      );
    }
  }

  /// Send typing indicator
  void sendTypingIndicator() {
    final repo = ref.read(chatRepositoryProvider);
    repo.sendTypingIndicator(arg);
  }

  /// Load more messages (pagination)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoading) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoading: true));

    final repo = ref.read(chatRepositoryProvider);
    final response = await repo.getMessages(
      arg,
      page: currentState.currentPage + 1,
    );

    state = AsyncData(
      currentState.copyWith(
        messages: [...response.messages.reversed, ...currentState.messages],
        isLoading: false,
        hasMore: response.hasMore,
        currentPage: currentState.currentPage + 1,
      ),
    );
  }
}

// --- WebSocket Connection Manager ---

final chatConnectionManagerProvider = Provider<ChatConnectionManager>((ref) {
  return ChatConnectionManager(ref);
});

class ChatConnectionManager {
  final Ref _ref;

  ChatConnectionManager(this._ref);

  /// Connect to WebSocket when user is authenticated
  Future<void> connect(String token) async {
    if (token.isEmpty) return;

    // Build WebSocket URL from API base URL
    // Assuming API is at http://localhost:3000, WS is at ws://localhost:3000/chat/ws
    const baseUrl = 'ws://localhost:3000/chat/ws'; // TODO: Get from config

    final repo = _ref.read(chatRepositoryProvider);
    await repo.connectWebSocket(baseUrl, token);
  }

  /// Connect using token from storage (preferred method)
  Future<void> connectWithStoredToken(String wsBaseUrl) async {
    final storageService = _ref.read(storageServiceProvider);
    final token = await storageService.getToken();

    if (token == null || token.isEmpty) return;

    final repo = _ref.read(chatRepositoryProvider);
    print('Nahid: Step 3');
    await repo.connectWebSocket(wsBaseUrl, token);

    // Register FCM device token after successful WebSocket connection
    // This ensures push notifications work for offline messages
    try {
      final fcmToken = await storageService.getFcmToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await repo.registerDevice(fcmToken);
      }
    } catch (e) {
      // FCM registration failure is non-critical, don't block connection
      // ignore: avoid_print
      print('FCM registration failed: $e');
    }
  }

  /// Disconnect WebSocket
  void disconnect() {
    final repo = _ref.read(chatRepositoryProvider);
    repo.disconnectWebSocket();
  }
}
