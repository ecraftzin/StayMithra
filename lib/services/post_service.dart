import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

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
    List<String> videoUrls = const [],
    String? location,
  }) async {
    try {
      // Determine media type
      String mediaType = 'image';
      if (videoUrls.isNotEmpty && imageUrls.isNotEmpty) {
        mediaType = 'mixed';
      } else if (videoUrls.isNotEmpty) {
        mediaType = 'video';
      }

      final response = await _supabase.from('posts').insert({
        'user_id': userId,
        'content': content,
        'image_urls': imageUrls,
        'video_urls': videoUrls,
        'media_type': mediaType,
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
      // Insert like
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });

      // Update likes count
      final response = await _supabase.rpc('increment_post_likes', params: {
        'post_id': postId,
      });

      return response as int? ?? 0;
    } catch (e) {
      print('Error liking post: $e');
      return 0;
    }
  }

  // Unlike a post
  Future<int> unlikePost(String postId, String userId) async {
    try {
      // Remove like
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);

      // Update likes count
      final response = await _supabase.rpc('decrement_post_likes', params: {
        'post_id': postId,
      });

      return response as int? ?? 0;
    } catch (e) {
      print('Error unliking post: $e');
      return 0;
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
      print('Error checking like status: $e');
      return false;
    }
  }

  // Add comment to post
  Future<CommentModel?> addComment(String postId, String content) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': currentUser.id,
        'content': content,
      }).select('''
        *,
        users(*)
      ''').single();

      // Update comments count manually
      final postData = await _supabase
          .from('posts')
          .select('comments_count')
          .eq('id', postId)
          .single();

      final currentCount = postData['comments_count'] as int? ?? 0;
      await _supabase
          .from('posts')
          .update({'comments_count': currentCount + 1}).eq('id', postId);

      return CommentModel.fromJson(response);
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      final response = await _supabase.from('post_comments').select('''
            *,
            user:users(*)
          ''').eq('post_id', postId).order('created_at', ascending: false);

      return (response as List)
          .map((comment) => CommentModel.fromJson(comment))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Share a post
  Future<String?> sharePost(String postId, String userId) async {
    try {
      final shareUrl = 'https://staymitra.app/post/$postId';

      await _supabase.from('shares').insert({
        'user_id': userId,
        'content_type': 'post',
        'content_id': postId,
        'shared_url': shareUrl,
      });

      // Update shares count
      await _supabase.rpc('increment_post_shares', params: {
        'post_id': postId,
      });

      return shareUrl;
    } catch (e) {
      print('Error sharing post: $e');
      return null;
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
