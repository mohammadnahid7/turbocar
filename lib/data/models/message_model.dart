/// Message Model
/// Represents a single chat message
library;

import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'sender_name')
  final String? senderName;
  final String content;
  @JsonKey(name: 'message_type')
  final String messageType; // text, image, file
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'is_read')
  final bool isRead;
  final String status; // sent, delivered, seen
  @JsonKey(name: 'delivered_at')
  final String? deliveredAt;
  @JsonKey(name: 'seen_at')
  final String? seenAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    this.messageType = 'text',
    this.mediaUrl,
    this.isRead = false,
    this.status = 'sent',
    this.deliveredAt,
    this.seenAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  /// Parse createdAt to DateTime
  DateTime get timestamp => DateTime.parse(createdAt);

  /// Check if this message is from the current user
  bool isFromMe(String currentUserId) => senderId == currentUserId;

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    String? messageType,
    String? mediaUrl,
    bool? isRead,
    String? status,
    String? deliveredAt,
    String? seenAt,
    String? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      seenAt: seenAt ?? this.seenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// WebSocket message for real-time communication
@JsonSerializable()
class WSMessage {
  final String
  type; // message, typing, read_receipt, message:delivered, messages:seen, unread:update, unread:get
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'sender_id')
  final String? senderId;
  final String? content;
  @JsonKey(name: 'message_type')
  final String? messageType;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  final String? timestamp;

  WSMessage({
    required this.type,
    required this.conversationId,
    this.senderId,
    this.content,
    this.messageType,
    this.mediaUrl,
    this.timestamp,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) =>
      _$WSMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WSMessageToJson(this);

  /// Create a text message
  factory WSMessage.text({
    required String conversationId,
    required String content,
  }) {
    return WSMessage(
      type: 'message',
      conversationId: conversationId,
      content: content,
      messageType: 'text',
    );
  }

  /// Create a typing indicator
  factory WSMessage.typing({required String conversationId}) {
    return WSMessage(type: 'typing', conversationId: conversationId);
  }

  /// Create a read receipt
  factory WSMessage.readReceipt({
    required String conversationId,
    required String messageId,
  }) {
    return WSMessage(
      type: 'read_receipt',
      conversationId: conversationId,
      content: messageId,
    );
  }

  /// Confirm message delivery
  factory WSMessage.delivered({
    required String conversationId,
    required String messageId,
  }) {
    return WSMessage(
      type: 'message:delivered',
      conversationId: conversationId,
      content: messageId,
    );
  }

  /// Mark all messages in conversation as seen
  factory WSMessage.seen({required String conversationId}) {
    return WSMessage(type: 'messages:seen', conversationId: conversationId);
  }

  /// Request current unread count
  factory WSMessage.getUnread() {
    return WSMessage(type: 'unread:get', conversationId: '');
  }
}
