import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseClient _supabase = supabase;

  // Get notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((notification) => NotificationModel.fromJson(notification))
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Create notification (for system use)
  Future<bool> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
      });

      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Create notification for post like
  Future<bool> createPostLikeNotification({
    required String postOwnerId,
    required String likerUserId,
    required String postId,
  }) async {
    try {
      // Don't notify if user likes their own post
      if (postOwnerId == likerUserId) return true;

      // Get liker's username
      final likerResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', likerUserId)
          .single();

      final likerUsername = likerResponse['username'] as String;

      return await createNotification(
        userId: postOwnerId,
        type: 'post_like',
        title: 'New Like',
        message: '$likerUsername liked your post',
        data: {
          'post_id': postId,
          'liker_id': likerUserId,
        },
      );
    } catch (e) {
      print('Error creating post like notification: $e');
      return false;
    }
  }

  // Create notification for post comment
  Future<bool> createPostCommentNotification({
    required String postOwnerId,
    required String commenterId,
    required String postId,
    required String commentId,
  }) async {
    try {
      // Don't notify if user comments on their own post
      if (postOwnerId == commenterId) return true;

      // Get commenter's username
      final commenterResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', commenterId)
          .single();

      final commenterUsername = commenterResponse['username'] as String;

      return await createNotification(
        userId: postOwnerId,
        type: 'post_comment',
        title: 'New Comment',
        message: '$commenterUsername commented on your post',
        data: {
          'post_id': postId,
          'comment_id': commentId,
          'commenter_id': commenterId,
        },
      );
    } catch (e) {
      print('Error creating post comment notification: $e');
      return false;
    }
  }

  // Create notification for campaign like
  Future<bool> createCampaignLikeNotification({
    required String campaignOwnerId,
    required String likerUserId,
    required String campaignId,
  }) async {
    try {
      // Don't notify if user likes their own campaign
      if (campaignOwnerId == likerUserId) return true;

      // Get liker's username
      final likerResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', likerUserId)
          .single();

      final likerUsername = likerResponse['username'] as String;

      return await createNotification(
        userId: campaignOwnerId,
        type: 'campaign_like',
        title: 'New Like',
        message: '$likerUsername liked your campaign',
        data: {
          'campaign_id': campaignId,
          'liker_id': likerUserId,
        },
      );
    } catch (e) {
      print('Error creating campaign like notification: $e');
      return false;
    }
  }

  // Create notification for campaign comment
  Future<bool> createCampaignCommentNotification({
    required String campaignOwnerId,
    required String commenterId,
    required String campaignId,
    required String commentId,
  }) async {
    try {
      // Don't notify if user comments on their own campaign
      if (campaignOwnerId == commenterId) return true;

      // Get commenter's username
      final commenterResponse = await _supabase
          .from('users')
          .select('username')
          .eq('id', commenterId)
          .single();

      final commenterUsername = commenterResponse['username'] as String;

      return await createNotification(
        userId: campaignOwnerId,
        type: 'campaign_comment',
        title: 'New Comment',
        message: '$commenterUsername commented on your campaign',
        data: {
          'campaign_id': campaignId,
          'comment_id': commentId,
          'commenter_id': commenterId,
        },
      );
    } catch (e) {
      print('Error creating campaign comment notification: $e');
      return false;
    }
  }

  // Subscribe to new notifications
  RealtimeChannel subscribeToNotifications(Function(NotificationModel) onNewNotification) {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('notifications_${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            try {
              final notification = NotificationModel.fromJson(payload.newRecord);
              onNewNotification(notification);
            } catch (e) {
              print('Error processing new notification: $e');
            }
          },
        )
        .subscribe();
  }
}
