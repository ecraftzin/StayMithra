import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class FollowRequestService {
  static final FollowRequestService _instance = FollowRequestService._internal();
  factory FollowRequestService() => _instance;
  FollowRequestService._internal();

  final SupabaseClient _supabase = supabase;

  // Send a follow request
  Future<bool> sendFollowRequest(String targetUserId) async {
    try {
      final response = await _supabase.rpc('send_follow_request', params: {
        'target_user_id': targetUserId,
      });
      
      return response == true;
    } catch (e) {
      print('Error sending follow request: $e');
      return false;
    }
  }

  // Accept a follow request
  Future<bool> acceptFollowRequest(String requestId) async {
    try {
      final response = await _supabase.rpc('accept_follow_request', params: {
        'request_id': requestId,
      });
      
      return response == true;
    } catch (e) {
      print('Error accepting follow request: $e');
      return false;
    }
  }

  // Reject a follow request
  Future<bool> rejectFollowRequest(String requestId) async {
    try {
      final response = await _supabase.rpc('reject_follow_request', params: {
        'request_id': requestId,
      });
      
      return response == true;
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
      final response = await _supabase
          .from('follows')
          .select('''
            follower:users!follows_follower_id_fkey(*)
          ''')
          .eq('following_id', userId);

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
      final response = await _supabase
          .from('follows')
          .select('''
            following:users!follows_following_id_fkey(*)
          ''')
          .eq('follower_id', userId);

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
