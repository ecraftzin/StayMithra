import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final SupabaseClient _supabase = supabase;

  // Check if users follow each other (mutual follow)
  Future<bool> _checkMutualFollow(String user1Id, String user2Id) async {
    try {
      // Check if user1 follows user2
      final user1FollowsUser2 = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user1Id)
          .eq('following_id', user2Id)
          .maybeSingle();

      // Check if user2 follows user1
      final user2FollowsUser1 = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user2Id)
          .eq('following_id', user1Id)
          .maybeSingle();

      // Both must follow each other for chat
      return user1FollowsUser2 != null && user2FollowsUser1 != null;
    } catch (e) {
      print('Error checking mutual follow: $e');
      return false;
    }
  }

  // Create or get existing chat between two users
  Future<ChatModel?> createOrGetChat(String user1Id, String user2Id) async {
    try {
      // Note: Follow check is handled in the calling code

      // Ensure consistent ordering (smaller ID first)
      final sortedUser1 = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
      final sortedUser2 = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

      // Try to find existing chat
      var response = await _supabase
          .from('chats')
          .select('''
            *,
            user1:users!chats_user1_id_fkey(*),
            user2:users!chats_user2_id_fkey(*)
          ''')
          .eq('user1_id', sortedUser1)
          .eq('user2_id', sortedUser2)
          .maybeSingle();

      if (response != null) {
        return _parseChatWithUsers(response, user1Id);
      }

      // Create new chat if doesn't exist
      response = await _supabase.from('chats').insert({
        'user1_id': sortedUser1,
        'user2_id': sortedUser2,
      }).select('''
            *,
            user1:users!chats_user1_id_fkey(*),
            user2:users!chats_user2_id_fkey(*)
          ''').single();

      return _parseChatWithUsers(response, user1Id);
    } catch (e) {
      print('Error creating/getting chat: $e');
      return null;
    }
  }

  // Get all chats for a user
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      final response = await _supabase
          .from('chats')
          .select('''
            *,
            user1:users!chats_user1_id_fkey(*),
            user2:users!chats_user2_id_fkey(*),
            messages:messages(*)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return (response as List)
          .map((chat) => _parseChatWithUsers(chat, userId))
          .where((chat) => chat != null)
          .cast<ChatModel>()
          .toList();
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  // Send a message
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      // Insert message
      final messageResponse = await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
        'is_read': false, // Explicitly set as unread
      }).select('''
            *,
            sender:users(*)
          ''').single();

      // Update chat's last_message_at
      await _supabase
          .from('chats')
          .update({'last_message_at': DateTime.now().toIso8601String()}).eq(
              'id', chatId);

      return MessageModel.fromJson(messageResponse);
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Get messages for a chat
  Future<List<MessageModel>> getChatMessages(String chatId,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:users(*)
          ''')
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((message) => MessageModel.fromJson(message))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  // Mark messages as read - simplified approach
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      print('DEBUG: Marking messages as read for chat $chatId, user $userId');

      // First, check how many messages exist in this chat
      final allMessages = await _supabase
          .from('messages')
          .select('id, sender_id, is_read')
          .eq('chat_id', chatId);
      print('DEBUG: Found ${allMessages.length} total messages in chat');

      final otherUserMessages =
          allMessages.where((msg) => msg['sender_id'] != userId).toList();
      print(
          'DEBUG: Found ${otherUserMessages.length} messages from other users');

      // Update ALL messages in this chat that are not from current user to be unread first
      final fixResult = await _supabase
          .from('messages')
          .update({'is_read': false})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .select();
      print('DEBUG: Set ${fixResult.length} messages to unread first');

      // Then mark them all as read
      final result = await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .select();
      print('DEBUG: Marked ${result.length} messages as read');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final chatIds = await _getUserChatIds(userId);
      if (chatIds.isEmpty) return 0;

      final response = await _supabase
          .from('messages')
          .select('id')
          .neq('sender_id', userId)
          .eq('is_read', false)
          .inFilter('chat_id', chatIds);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Subscribe to new messages in a chat
  RealtimeChannel subscribeToChat(
      String chatId, Function(MessageModel) onNewMessage) {
    return _supabase
        .channel('chat_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            try {
              // Fetch the complete message with sender info
              final messageResponse =
                  await _supabase.from('messages').select('''
                    *,
                    sender:users(*)
                  ''').eq('id', payload.newRecord['id']).single();

              final message = MessageModel.fromJson(messageResponse);
              onNewMessage(message);
            } catch (e) {
              print('Error processing new message: $e');
            }
          },
        )
        .subscribe();
  }

  // Helper method to parse chat with user information
  ChatModel? _parseChatWithUsers(
      Map<String, dynamic> chatData, String currentUserId) {
    try {
      final user1Data = chatData['user1'];
      final user2Data = chatData['user2'];

      // Determine which user is the "other" user
      UserModel? otherUser;
      if (user1Data != null && user1Data['id'] != currentUserId) {
        try {
          otherUser = UserModel.fromJson(user1Data);
        } catch (e) {
          print('Error creating UserModel from user1Data: $e');
        }
      } else if (user2Data != null && user2Data['id'] != currentUserId) {
        try {
          otherUser = UserModel.fromJson(user2Data);
        } catch (e) {
          print('Error creating UserModel from user2Data: $e');
        }
      }

      // Get last message and calculate unread count
      MessageModel? lastMessage;
      int unreadCount = 0;
      if (chatData['messages'] != null &&
          (chatData['messages'] as List).isNotEmpty) {
        final messages = chatData['messages'] as List;
        messages.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
        lastMessage = MessageModel.fromJson(messages.first);

        // Count unread messages (messages not sent by current user and not read)
        unreadCount = messages
            .where((msg) =>
                msg['sender_id'] != currentUserId &&
                (msg['is_read'] == false || msg['is_read'] == null))
            .length;
      }

      return ChatModel(
        id: chatData['id'],
        user1Id: chatData['user1_id'],
        user2Id: chatData['user2_id'],
        lastMessageAt: DateTime.parse(chatData['last_message_at']),
        createdAt: DateTime.parse(chatData['created_at']),
        otherUser: otherUser,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error parsing chat with users: $e');
      return null;
    }
  }

  // Helper method to get chat IDs for a user
  Future<List<String>> _getUserChatIds(String userId) async {
    try {
      final response = await _supabase
          .from('chats')
          .select('id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      return (response as List).map((chat) => chat['id'] as String).toList();
    } catch (e) {
      print('Error getting user chat IDs: $e');
      return [];
    }
  }
}
