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

// --- Conversation Providers ---

/// List of all conversations
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
      ConversationsNotifier.new,
    );

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
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
    Map<String, dynamic>? context,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversation = await repo.startConversation(
      participantIds,
      context: context,
    );
    await refresh();
    return conversation;
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
        createdAt: wsMessage.timestamp ?? DateTime.now().toIso8601String(),
      );

      state = AsyncData(
        currentState.copyWith(messages: [...currentState.messages, newMessage]),
      );
    } else if (wsMessage.type == 'typing') {
      // Show typing indicator
      state = AsyncData(currentState.copyWith(isTyping: true));

      // Hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.hasValue) {
          state = AsyncData(state.value!.copyWith(isTyping: false));
        }
      });
    } else if (wsMessage.type == 'read_receipt') {
      // Update read status for messages
      final updatedMessages = currentState.messages.map((msg) {
        if (msg.createdAt.compareTo(wsMessage.content ?? '') <= 0) {
          return MessageModel(
            id: msg.id,
            conversationId: msg.conversationId,
            senderId: msg.senderId,
            senderName: msg.senderName,
            content: msg.content,
            messageType: msg.messageType,
            mediaUrl: msg.mediaUrl,
            isRead: true,
            createdAt: msg.createdAt,
          );
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
