import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final SupabaseClient _supabase = supabase;

  // Create a new post
  Future<PostModel?> createPost({
    required String userId,
    required String content,
    List<String> imageUrls = const [],
    String? location,
  }) async {
    try {
      final response = await _supabase.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_urls': imageUrls,
        'location': location,
      }).select('''
            *,
            users(*)
          ''').single();

      return PostModel.fromJson(response);
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // Get all posts (feed)
  Future<List<PostModel>> getAllPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users(*)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((post) => PostModel.fromJson(post))
          .toList();
    } catch (e) {
      print('Error getting all posts: $e');
      return [];
    }
  }

  // Get posts by user
  Future<List<PostModel>> getUserPosts(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((post) => PostModel.fromJson(post))
          .toList();
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }

  // Get a single post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response = await _supabase.from('posts').select('''
            *,
            users(*)
          ''').eq('id', postId).single();

      return PostModel.fromJson(response);
    } catch (e) {
      print('Error getting post by ID: $e');
      return null;
    }
  }

  // Update a post
  Future<PostModel?> updatePost({
    required String postId,
    required String userId,
    String? content,
    List<String>? imageUrls,
    String? location,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (content != null) updates['content'] = content;
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (location != null) updates['location'] = location;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('posts')
          .update(updates)
          .eq('id', postId)
          .eq('user_id', userId) // Ensure user can only update their own posts
          .select('''
            *,
            users(*)
          ''').single();

      return PostModel.fromJson(response);
    } catch (e) {
      print('Error updating post: $e');
      return null;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId, String userId) async {
    try {
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId); // Ensure user can only delete their own posts

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Like a post
  Future<int> likePost(String postId, String userId) async {
    try {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });

      // Get updated like count
      final response =
          await _supabase.from('post_likes').select('id').eq('post_id', postId);

      return response.length;
    } catch (e) {
      print('Error liking post: $e');
      rethrow;
    }
  }

  // Unlike a post
  Future<int> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      // Get updated like count
      final response =
          await _supabase.from('post_likes').select('id').eq('post_id', postId);

      return response.length;
    } catch (e) {
      print('Error unliking post: $e');
      rethrow;
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final response = await _supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user liked post: $e');
      return false;
    }
  }

  // Add a comment to a post
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content,
      });

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await _supabase.from('post_comments').select('''
            *,
            users(*)
          ''').eq('post_id', postId).order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting post comments: $e');
      return [];
    }
  }

  // Get posts with like status for a specific user
  Future<List<Map<String, dynamic>>> getPostsWithLikeStatus(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users(*),
            post_likes!left(user_id)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((post) {
        final likes = post['post_likes'] as List?;
        final hasLiked =
            likes?.any((like) => like['user_id'] == userId) ?? false;

        return Map<String, dynamic>.from({
          ...post,
          'has_liked': hasLiked,
        });
      }).toList();
    } catch (e) {
      print('Error getting posts with like status: $e');
      return [];
    }
  }

  // Subscribe to new posts
  RealtimeChannel subscribeToNewPosts(Function(PostModel) onNewPost) {
    return _supabase
        .channel('new_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) async {
            try {
              // Fetch the complete post with user info
              final postResponse = await _supabase.from('posts').select('''
                    *,
                    users(*)
                  ''').eq('id', payload.newRecord['id']).single();

              final post = PostModel.fromJson(postResponse);
              onNewPost(post);
            } catch (e) {
              print('Error processing new post: $e');
            }
          },
        )
        .subscribe();
  }
}
