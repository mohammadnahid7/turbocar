/// Chat Repository
/// Combines API and WebSocket functionality for chat
library;

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';

class ChatRepository {
  final ChatService _chatService;
  final SocketService _socketService;

  ChatRepository({
    required ChatService chatService,
    required SocketService socketService,
  }) : _chatService = chatService,
       _socketService = socketService;

  // --- WebSocket ---

  /// Connect to WebSocket server
  Future<void> connectWebSocket(String serverUrl, String token) async {
    await _socketService.connect(serverUrl, token);
  }

  /// Disconnect from WebSocket
  void disconnectWebSocket() {
    _socketService.disconnect();
  }

  /// Stream of incoming messages
  Stream<WSMessage> get messageStream => _socketService.messageStream;

  /// Stream of connection state changes
  Stream<SocketConnectionState> get connectionStateStream =>
      _socketService.connectionStateStream;

  /// Whether WebSocket is connected
  bool get isConnected => _socketService.isConnected;

  /// Send a message via WebSocket
  void sendMessage(WSMessage message) {
    _socketService.send(message);
  }

  /// Send a text message
  void sendTextMessage(String conversationId, String content) {
    _socketService.send(
      WSMessage.text(conversationId: conversationId, content: content),
    );
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId) {
    _socketService.send(WSMessage.typing(conversationId: conversationId));
  }

  /// Send read receipt
  void sendReadReceipt(String conversationId, String messageId) {
    _socketService.send(
      WSMessage.readReceipt(
        conversationId: conversationId,
        messageId: messageId,
      ),
    );
  }

  /// Send delivered acknowledgment
  void sendDelivered(String conversationId, String messageId) {
    _socketService.send(
      WSMessage.delivered(conversationId: conversationId, messageId: messageId),
    );
  }

  /// Mark all messages in conversation as seen
  void sendSeen(String conversationId) {
    _socketService.send(WSMessage.seen(conversationId: conversationId));
  }

  /// Request current total unread count
  void requestUnreadCount() {
    _socketService.send(WSMessage.getUnread());
  }

  // --- REST API ---

  /// Get all conversations
  Future<List<ConversationModel>> getConversations() {
    return _chatService.getConversations();
  }

  /// Start or get existing conversation
  Future<ConversationModel> startConversation(
    List<String> participantIds, {
    String? carId,
    String? carTitle,
    Map<String, dynamic>? context,
  }) {
    return _chatService.startConversation(
      participantIds,
      carId: carId,
      carTitle: carTitle,
      context: context,
    );
  }

  /// Get message history
  Future<ChatHistoryResponse> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) {
    return _chatService.getMessages(
      conversationId,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Register device for push notifications
  Future<void> registerDevice(
    String fcmToken, {
    String deviceType = 'android',
  }) {
    return _chatService.registerDevice(fcmToken, deviceType: deviceType);
  }

  /// Unregister device from push notifications
  Future<void> unregisterDevice(String fcmToken) {
    return _chatService.unregisterDevice(fcmToken);
  }

  /// Dispose resources
  void dispose() {
    _socketService.dispose();
  }
}
