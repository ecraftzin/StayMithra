import 'user_model.dart';

class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final UserModel? otherUser; // The other user in the chat
  final MessageModel? lastMessage; // Last message for preview
  final int unreadCount; // Number of unread messages

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessageAt,
    required this.createdAt,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      otherUser: json['other_user'] != null
          ? UserModel.fromJson(json['other_user'])
          : null,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'last_message_at': lastMessageAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final UserModel? sender; // For joined queries

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender:
          json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? messageType,
    bool? isRead,
    DateTime? createdAt,
    UserModel? sender,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }
}
