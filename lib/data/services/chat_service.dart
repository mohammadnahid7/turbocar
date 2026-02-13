/// Chat Service
/// Handles HTTP API calls for chat functionality
library;

import 'package:dio/dio.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  /// Get all conversations for the current user
  Future<List<ConversationModel>> getConversations() async {
    final response = await _dio.get('/chat/conversations');
    final List<dynamic> data = response.data;
    return data.map((json) => ConversationModel.fromJson(json)).toList();
  }

  /// Start a new conversation with specified users
  Future<ConversationModel> startConversation(
    List<String> participantIds, {
    String? carId,
    String? carTitle,
    Map<String, dynamic>? context,
  }) async {
    final data = <String, dynamic>{'participant_ids': participantIds};
    // Send car data at top level (not nested in context)
    if (carId != null) {
      data['car_id'] = carId;
    }
    if (carTitle != null) {
      data['car_title'] = carTitle;
    }
    if (context != null) {
      data['context'] = context;
    }

    // DEBUG: Log what we're sending
    print('DEBUG ChatService.startConversation - Request data: $data');

    final response = await _dio.post('/chat/conversations', data: data);

    // DEBUG: Log what we received
    print('DEBUG ChatService.startConversation - Response: ${response.data}');

    return ConversationModel.fromJson(response.data);
  }

  /// Get message history for a conversation
  Future<ChatHistoryResponse> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return ChatHistoryResponse.fromJson(response.data);
  }

  /// Register FCM device token
  Future<void> registerDevice(
    String fcmToken, {
    String deviceType = 'android',
  }) async {
    await _dio.post(
      '/chat/device',
      data: {'fcm_token': fcmToken, 'device_type': deviceType},
    );
  }

  /// Unregister FCM device token
  Future<void> unregisterDevice(String fcmToken) async {
    await _dio.delete('/chat/device', data: {'fcm_token': fcmToken});
  }
}

/// Response for chat history with pagination
class ChatHistoryResponse {
  final List<MessageModel> messages;
  final int totalCount;
  final int page;
  final int pageSize;

  ChatHistoryResponse({
    required this.messages,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messagesJson = json['messages'] ?? [];
    return ChatHistoryResponse(
      messages: messagesJson.map((m) => MessageModel.fromJson(m)).toList(),
      totalCount: json['total_count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 50,
    );
  }

  bool get hasMore => page * pageSize < totalCount;
}
