/// Chat Room Data
/// Data class to pass car/seller context when opening a chat room
/// Used for both existing conversations and pending (lazy) conversations
library;

import 'conversation_model.dart';

/// Data passed when navigating to chat room
/// Can represent either an existing conversation or a pending one
class ChatRoomData {
  /// Existing conversation (null if pending)
  final ConversationModel? existingConversation;

  /// Seller info (for pending conversations)
  final String? sellerId;
  final String? sellerName;
  final String? sellerAvatar;

  /// Car info (passed from car details page for pending conversations)
  final String? carId;
  final String? carTitle;
  final String? carImageUrl;
  final double? carPrice;

  const ChatRoomData({
    this.existingConversation,
    this.sellerId,
    this.sellerName,
    this.sellerAvatar,
    this.carId,
    this.carTitle,
    this.carImageUrl,
    this.carPrice,
  });

  /// Factory for existing conversation
  factory ChatRoomData.fromConversation(ConversationModel conversation) {
    return ChatRoomData(
      existingConversation: conversation,
      carId: conversation.carId,
      carTitle: conversation.carTitle,
      carImageUrl: conversation.carImageUrl,
      carPrice: conversation.carPrice,
    );
  }

  /// Factory for pending conversation (from car details page)
  factory ChatRoomData.pending({
    required String sellerId,
    String? sellerName,
    String? sellerAvatar,
    required String carId,
    required String carTitle,
    String? carImageUrl,
    double? carPrice,
  }) {
    return ChatRoomData(
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAvatar: sellerAvatar,
      carId: carId,
      carTitle: carTitle,
      carImageUrl: carImageUrl,
      carPrice: carPrice,
    );
  }

  /// Whether this represents a pending (not yet created) conversation
  bool get isPending => existingConversation == null;

  /// Get conversation ID if exists
  String? get conversationId => existingConversation?.id;
}
