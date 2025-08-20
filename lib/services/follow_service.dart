import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Follow a user
  Future<bool> followUser(String followerId, String followingId) async {
    try {
      await _supabase.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });
      return true;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String followerId, String followingId) async {
    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
      return true;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
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
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            follower_id,
            users!follows_follower_id_fkey(id, username, full_name, avatar_url)
          ''')
          .eq('following_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  // Get users that user is following
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            following_id,
            users!follows_following_id_fkey(id, username, full_name, avatar_url)
          ''')
          .eq('follower_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }
}
