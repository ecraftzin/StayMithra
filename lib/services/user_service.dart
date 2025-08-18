import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final SupabaseClient _supabase = supabase;

  // Search users by username or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('users')
          .select()
          .or('username.ilike.%$query%,email.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  // Get recent users (newly joined)
  Future<List<UserModel>> getRecentUsers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error getting recent users: $e');
      return [];
    }
  }

  // Get all users (for admin purposes or general listing)
  Future<List<UserModel>> getAllUsers({int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Update user profile
  Future<UserModel?> updateUserProfile({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (website != null) updates['website'] = website;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if username exists
  Future<bool> usernameExists(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Get user stats (posts count, etc.)
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get posts count
      final postsResponse =
          await _supabase.from('posts').select('id').eq('user_id', userId);

      // Get campaigns count
      final campaignsResponse =
          await _supabase.from('campaigns').select('id').eq('user_id', userId);

      return {
        'posts': (postsResponse as List).length,
        'campaigns': (campaignsResponse as List).length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'posts': 0, 'campaigns': 0};
    }
  }
}
