import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';
import '../models/user_model.dart';

class FollowRequestService {
  static final FollowRequestService _instance =
      FollowRequestService._internal();
  factory FollowRequestService() => _instance;
  FollowRequestService._internal();

  final SupabaseClient _supabase = supabase;
  final NotificationService _notificationService = NotificationService();

  // Send a follow request
  Future<bool> sendFollowRequest(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Prevent users from following themselves
      if (currentUser.id == targetUserId) {
        print('Cannot send follow request to yourself');
        return false;
      }

      // Check if request already exists
      final existingRequest = await _supabase
          .from('follow_requests')
          .select('id, status')
          .eq('requester_id', currentUser.id)
          .eq('requested_id', targetUserId)
          .maybeSingle();

      if (existingRequest != null) {
        final status = existingRequest['status'] as String;
        if (status == 'pending') {
          print('Follow request already exists and is pending');
          return true; // Return true so UI shows "Requested"
        } else if (status == 'accepted') {
          print('Follow request already accepted');
          return false; // Already accepted, no need to send again
        }
      }

      // Insert new follow request
      await _supabase.from('follow_requests').insert({
        'requester_id': currentUser.id,
        'requested_id': targetUserId,
        'status': 'pending',
      });

      // Get requester user info for notification
      final requesterInfo = await _supabase
          .from('users')
          .select('username, full_name')
          .eq('id', currentUser.id)
          .single();

      // Create notification for the target user
      await _notificationService.createNotification(
        userId: targetUserId,
        type: 'follow_request',
        title: 'New Follow Request',
        message: '${requesterInfo['username']} wants to follow you',
        data: {
          'requester_id': currentUser.id,
          'requester_username': requesterInfo['username'],
          'requester_full_name': requesterInfo['full_name'],
        },
      );

      return true;
    } catch (e) {
      print('Error sending follow request: $e');
      return false;
    }
  }

  // Accept a follow request
  Future<bool> acceptFollowRequest(String requestId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      // Get the follow request details
      final request = await _supabase
          .from('follow_requests')
          .select('requester_id, requested_id')
          .eq('id', requestId)
          .eq('status', 'pending')
          .eq('requested_id',
              currentUser.id) // Ensure current user is the one being requested
          .single();

      // Update request status to accepted
      await _supabase
          .from('follow_requests')
          .update({'status': 'accepted'}).eq('id', requestId);

      // Add to follows table (current user accepts, so requester follows current user)
      await _supabase.from('follows').insert({
        'follower_id': request['requester_id'],
        'following_id': request['requested_id'],
      });

      // Get accepter user info for notification
      final accepterInfo = await _supabase
          .from('users')
          .select('username, full_name')
          .eq('id', request['requested_id'])
          .single();

      // Create notification for the requester
      await _notificationService.createNotification(
        userId: request['requester_id'],
        type: 'follow_accepted',
        title: 'Follow Request Accepted',
        message: '${accepterInfo['username']} accepted your follow request',
        data: {
          'accepter_id': request['requested_id'],
          'accepter_username': accepterInfo['username'],
          'accepter_full_name': accepterInfo['full_name'],
        },
      );

      return true;
    } catch (e) {
      print('Error accepting follow request: $e');
      return false;
    }
  }

  // Reject a follow request
  Future<bool> rejectFollowRequest(String requestId) async {
    try {
      // Update request status to rejected
      await _supabase
          .from('follow_requests')
          .update({'status': 'rejected'}).eq('id', requestId);

      return true;
    } catch (e) {
      print('Error rejecting follow request: $e');
      return false;
    }
  }

  // Get pending follow requests for current user
  Future<List<Map<String, dynamic>>> getPendingFollowRequests() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('follow_requests')
          .select('''
            id,
            requester_id,
            requested_id,
            status,
            created_at,
            requester:users!follow_requests_requester_id_fkey(id, username, full_name, avatar_url)
          ''')
          .eq('requested_id', currentUser.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending follow requests: $e');
      return [];
    }
  }

  // Get sent follow requests (pending)
  Future<List<Map<String, dynamic>>> getSentFollowRequests() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('follow_requests')
          .select('''
            id,
            requester_id,
            requested_id,
            status,
            created_at,
            requested:users!follow_requests_requested_id_fkey(id, username, full_name, avatar_url)
          ''')
          .eq('requester_id', currentUser.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting sent follow requests: $e');
      return [];
    }
  }

  // Check if user has sent a follow request to another user
  Future<bool> hasPendingRequest(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('follow_requests')
          .select('id')
          .eq('requester_id', currentUser.id)
          .eq('requested_id', targetUserId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }

  // Check if users are following each other
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Get comprehensive follow status between current user and target user
  Future<String> getFollowStatus(
      String currentUserId, String targetUserId) async {
    try {
      // Check if current user is following target user
      final isCurrentFollowingTarget = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      // Check if target user is following current user
      final isTargetFollowingCurrent = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', targetUserId)
          .eq('following_id', currentUserId)
          .maybeSingle();

      // Check if there's a pending request from current user to target user
      final hasPendingRequest = await _supabase
          .from('follow_requests')
          .select('id')
          .eq('requester_id', currentUserId)
          .eq('requested_id', targetUserId)
          .eq('status', 'pending')
          .maybeSingle();

      // Check for accepted request (either direction) that might not have follow relationship yet
      final acceptedRequests = await _supabase
          .from('follow_requests')
          .select('id, requester_id, requested_id')
          .or('and(requester_id.eq.$currentUserId,requested_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,requested_id.eq.$currentUserId)')
          .eq('status', 'accepted');

      final hasAcceptedRequest =
          acceptedRequests.isNotEmpty ? acceptedRequests.first : null;

      // Determine status
      if (isCurrentFollowingTarget != null &&
          isTargetFollowingCurrent != null) {
        return 'mutual'; // Both follow each other
      } else if (isCurrentFollowingTarget != null) {
        return 'following'; // Current user follows target
      } else if (isTargetFollowingCurrent != null) {
        return 'followed_by'; // Target follows current user
      } else if (hasAcceptedRequest != null) {
        // If there's an accepted request but no follow relationship, create it
        await _createFollowFromAcceptedRequest(hasAcceptedRequest);
        // Re-check the follow status after creating relationship
        final newFollowStatus = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', hasAcceptedRequest['requester_id'])
            .eq('following_id', hasAcceptedRequest['requested_id'])
            .maybeSingle();

        if (newFollowStatus != null) {
          // Check if it's mutual now
          if (hasAcceptedRequest['requester_id'] == currentUserId) {
            return 'following'; // Current user is now following target
          } else {
            return 'followed_by'; // Target is now following current user
          }
        }
      } else if (hasPendingRequest != null) {
        return 'requested'; // Request sent but not accepted
      }

      return 'not_following'; // Default fallback
    } catch (e) {
      print('Error getting follow status: $e');
      return 'not_following';
    }
  }

  // Helper method to create follow relationship from accepted request
  Future<void> _createFollowFromAcceptedRequest(
      Map<String, dynamic> acceptedRequest) async {
    try {
      final requesterId = acceptedRequest['requester_id'] as String;
      final requestedId = acceptedRequest['requested_id'] as String;

      // Check if follow relationship already exists
      final existingFollow = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', requesterId)
          .eq('following_id', requestedId)
          .maybeSingle();

      if (existingFollow == null) {
        // Create the follow relationship
        await _supabase.from('follows').insert({
          'follower_id': requesterId,
          'following_id': requestedId,
        });
      }
    } catch (e) {
      print('Error creating follow from accepted request: $e');
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', targetUserId);

      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Get followers count
  Future<int> getFollowersCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId);

      return response.length;
    } catch (e) {
      print('Error getting followers count: $e');
      return 0;
    }
  }

  // Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', userId);

      return response.length;
    } catch (e) {
      print('Error getting following count: $e');
      return 0;
    }
  }

  // Get user's followers
  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _supabase.from('follows').select('''
            follower:users!follows_follower_id_fkey(*)
          ''').eq('following_id', userId);

      return (response as List)
          .map((item) => UserModel.fromJson(item['follower']))
          .toList();
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get users that user is following
  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _supabase.from('follows').select('''
            following:users!follows_following_id_fkey(*)
          ''').eq('follower_id', userId);

      return (response as List)
          .map((item) => UserModel.fromJson(item['following']))
          .toList();
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // Cancel a sent follow request
  Future<bool> cancelFollowRequest(String targetUserId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('follow_requests')
          .delete()
          .eq('requester_id', currentUser.id)
          .eq('requested_id', targetUserId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      print('Error canceling follow request: $e');
      return false;
    }
  }
}
