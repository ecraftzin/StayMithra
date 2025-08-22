import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/campaign_model.dart';
import '../models/comment_model.dart';

class CampaignService {
  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal();

  final SupabaseClient _supabase = supabase;

  // Create a new campaign
  Future<CampaignModel?> createCampaign({
    required String userId,
    required String title,
    required String description,
    List<String> imageUrls = const [],
    List<String> videoUrls = const [],
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    double? price,
    String? category,
  }) async {
    try {
      // Determine media type
      String mediaType = 'image';
      if (videoUrls.isNotEmpty && imageUrls.isNotEmpty) {
        mediaType = 'mixed';
      } else if (videoUrls.isNotEmpty) {
        mediaType = 'video';
      }

      final response = await _supabase.from('campaigns').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'image_urls': imageUrls,
        'video_urls': videoUrls,
        'media_type': mediaType,
        'location': location,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'max_participants': maxParticipants,
        'price': price,
        'category': category,
      }).select('''
            *,
            users(*)
          ''').single();

      return CampaignModel.fromJson(response);
    } catch (e) {
      print('Error creating campaign: $e');
      return null;
    }
  }

  // Get all campaigns
  Future<List<CampaignModel>> getAllCampaigns({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('campaigns')
          .select('''
            *,
            users(*)
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((campaign) => CampaignModel.fromJson(campaign))
          .toList();
    } catch (e) {
      print('Error getting all campaigns: $e');
      return [];
    }
  }

  // Get filtered campaigns
  Future<List<CampaignModel>> getFilteredCampaigns({
    int limit = 20,
    int offset = 0,
    String? location,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('campaigns').select('''
            *,
            users(*)
          ''').eq('is_active', true);

      // Apply filters
      if (location != null && location.isNotEmpty) {
        query = query.ilike('location', '%$location%');
      }

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('end_date', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((campaign) => CampaignModel.fromJson(campaign))
          .toList();
    } catch (e) {
      print('Error getting filtered campaigns: $e');
      return [];
    }
  }

  // Get campaigns by user
  Future<List<CampaignModel>> getUserCampaigns(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('campaigns')
          .select('''
            *,
            users(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((campaign) => CampaignModel.fromJson(campaign))
          .toList();
    } catch (e) {
      print('Error getting user campaigns: $e');
      return [];
    }
  }

  // Get a single campaign by ID
  Future<CampaignModel?> getCampaignById(String campaignId) async {
    try {
      final response = await _supabase.from('campaigns').select('''
            *,
            users(*)
          ''').eq('id', campaignId).single();

      return CampaignModel.fromJson(response);
    } catch (e) {
      print('Error getting campaign by ID: $e');
      return null;
    }
  }

  // Update a campaign
  Future<CampaignModel?> updateCampaign({
    required String campaignId,
    required String userId,
    String? title,
    String? description,
    List<String>? imageUrls,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    double? price,
    String? category,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (location != null) updates['location'] = location;
      if (startDate != null) {
        updates['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) updates['end_date'] = endDate.toIso8601String();
      if (maxParticipants != null) {
        updates['max_participants'] = maxParticipants;
      }
      if (price != null) updates['price'] = price;
      if (category != null) updates['category'] = category;
      if (isActive != null) updates['is_active'] = isActive;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('campaigns')
          .update(updates)
          .eq('id', campaignId)
          .eq(
            'user_id',
            userId,
          ) // Ensure user can only update their own campaigns
          .select('''
            *,
            users(*)
          ''').single();

      return CampaignModel.fromJson(response);
    } catch (e) {
      print('Error updating campaign: $e');
      return null;
    }
  }

  // Delete a campaign
  Future<bool> deleteCampaign(String campaignId, String userId) async {
    try {
      await _supabase.from('campaigns').delete().eq('id', campaignId).eq(
            'user_id',
            userId,
          ); // Ensure user can only delete their own campaigns

      return true;
    } catch (e) {
      print('Error deleting campaign: $e');
      return false;
    }
  }

  // Join a campaign
  Future<bool> joinCampaign(String campaignId, String userId) async {
    try {
      // Check if user is already a participant
      final existingParticipant = await _supabase
          .from('campaign_participants')
          .select('id')
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingParticipant != null) {
        return false; // Already joined
      }

      // Check if campaign has space
      final campaign = await getCampaignById(campaignId);
      if (campaign != null &&
          campaign.maxParticipants != null &&
          campaign.currentParticipants >= campaign.maxParticipants!) {
        return false; // Campaign is full
      }

      // Add participant
      await _supabase.from('campaign_participants').insert({
        'campaign_id': campaignId,
        'user_id': userId,
      });

      // Update participant count
      await _supabase.from('campaigns').update({
        'current_participants': (campaign?.currentParticipants ?? 0) + 1,
      }).eq('id', campaignId);

      return true;
    } catch (e) {
      print('Error joining campaign: $e');
      return false;
    }
  }

  // Leave a campaign
  Future<bool> leaveCampaign(String campaignId, String userId) async {
    try {
      await _supabase
          .from('campaign_participants')
          .delete()
          .eq('campaign_id', campaignId)
          .eq('user_id', userId);

      // Update participant count
      final campaign = await getCampaignById(campaignId);
      if (campaign != null) {
        await _supabase.from('campaigns').update({
          'current_participants': (campaign.currentParticipants - 1)
              .clamp(0, double.infinity)
              .toInt(),
        }).eq('id', campaignId);
      }

      return true;
    } catch (e) {
      print('Error leaving campaign: $e');
      return false;
    }
  }

  // Check if user has joined a campaign
  Future<bool> hasUserJoinedCampaign(String campaignId, String userId) async {
    try {
      final response = await _supabase
          .from('campaign_participants')
          .select('id')
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user joined campaign: $e');
      return false;
    }
  }

  // Join campaign and return new participant count
  Future<int?> joinCampaignWithCount(String campaignId, String userId) async {
    try {
      // Check if user is already a participant
      final existingParticipant = await _supabase
          .from('campaign_participants')
          .select('id')
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingParticipant != null) {
        // Already joined, return current count
        final campaign = await getCampaignById(campaignId);
        return campaign?.currentParticipants ?? 0;
      }

      // Check if campaign has space
      final campaign = await getCampaignById(campaignId);
      if (campaign != null &&
          campaign.maxParticipants != null &&
          campaign.currentParticipants >= campaign.maxParticipants!) {
        return null; // Campaign is full
      }

      // Add participant
      await _supabase.from('campaign_participants').insert({
        'campaign_id': campaignId,
        'user_id': userId,
      });

      // Calculate new count
      final newCount = (campaign?.currentParticipants ?? 0) + 1;

      // Update participant count
      await _supabase.from('campaigns').update({
        'current_participants': newCount,
      }).eq('id', campaignId);

      return newCount;
    } catch (e) {
      print('Error joining campaign: $e');
      return null;
    }
  }

  // Get campaign participants
  Future<List<Map<String, dynamic>>> getCampaignParticipants(
    String campaignId,
  ) async {
    try {
      final response = await _supabase
          .from('campaign_participants')
          .select('''
            *,
            users(*)
          ''')
          .eq('campaign_id', campaignId)
          .order('joined_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting campaign participants: $e');
      return [];
    }
  }

  // Search campaigns
  Future<List<CampaignModel>> searchCampaigns(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('campaigns')
          .select('''
            *,
            users(*)
          ''')
          .or(
            'title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%,category.ilike.%$query%',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((campaign) => CampaignModel.fromJson(campaign))
          .toList();
    } catch (e) {
      print('Error searching campaigns: $e');
      return [];
    }
  }

  // Like a campaign
  Future<int> likeCampaign(String campaignId, String userId) async {
    try {
      // Check if already liked
      final existingLike = await _supabase
          .from('campaign_likes')
          .select()
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Already liked, return current count
        final campaign = await _supabase
            .from('campaigns')
            .select('likes_count')
            .eq('id', campaignId)
            .single();
        return campaign['likes_count'] as int? ?? 0;
      }

      // Add like
      await _supabase.from('campaign_likes').insert({
        'campaign_id': campaignId,
        'user_id': userId,
      });

      // Update campaign likes count
      final campaign = await _supabase
          .from('campaigns')
          .select('likes_count')
          .eq('id', campaignId)
          .single();

      final currentCount = campaign['likes_count'] as int? ?? 0;
      final newCount = currentCount + 1;

      await _supabase
          .from('campaigns')
          .update({'likes_count': newCount}).eq('id', campaignId);

      return newCount;
    } catch (e) {
      print('Error liking campaign: $e');
      rethrow;
    }
  }

  // Unlike a campaign
  Future<int> unlikeCampaign(String campaignId, String userId) async {
    try {
      // Remove like
      await _supabase
          .from('campaign_likes')
          .delete()
          .eq('campaign_id', campaignId)
          .eq('user_id', userId);

      // Update campaign likes count
      final campaign = await _supabase
          .from('campaigns')
          .select('likes_count')
          .eq('id', campaignId)
          .single();

      final currentCount = campaign['likes_count'] as int? ?? 0;
      final newCount = currentCount > 0 ? currentCount - 1 : 0;

      await _supabase
          .from('campaigns')
          .update({'likes_count': newCount}).eq('id', campaignId);

      return newCount;
    } catch (e) {
      print('Error unliking campaign: $e');
      rethrow;
    }
  }

  // Check if user has liked a campaign
  Future<bool> hasUserLikedCampaign(String campaignId, String userId) async {
    try {
      final like = await _supabase
          .from('campaign_likes')
          .select()
          .eq('campaign_id', campaignId)
          .eq('user_id', userId)
          .maybeSingle();

      return like != null;
    } catch (e) {
      print('Error checking campaign like status: $e');
      return false;
    }
  }

  // Get campaigns by category
  Future<List<CampaignModel>> getCampaignsByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('campaigns')
          .select('''
            *,
            users(*)
          ''')
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((campaign) => CampaignModel.fromJson(campaign))
          .toList();
    } catch (e) {
      print('Error getting campaigns by category: $e');
      return [];
    }
  }

  // Subscribe to new campaigns
  RealtimeChannel subscribeToNewCampaigns(
    Function(CampaignModel) onNewCampaign,
  ) {
    return _supabase
        .channel('new_campaigns')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'campaigns',
          callback: (payload) async {
            try {
              // Fetch the complete campaign with user info
              final campaignResponse =
                  await _supabase.from('campaigns').select('''
                    *,
                    users(*)
                  ''').eq('id', payload.newRecord['id']).single();

              final campaign = CampaignModel.fromJson(campaignResponse);
              onNewCampaign(campaign);
            } catch (e) {
              print('Error processing new campaign: $e');
            }
          },
        )
        .subscribe();
  }

  // Get comments for a campaign
  Future<List<CommentModel>> getCampaignComments(String campaignId) async {
    try {
      final response = await _supabase
          .from('campaign_comments')
          .select('''
            *,
            user:users(*)
          ''')
          .eq('campaign_id', campaignId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((comment) => CommentModel.fromJson(comment))
          .toList();
    } catch (e) {
      print('Error getting campaign comments: $e');
      return [];
    }
  }

  // Add comment to campaign
  Future<CommentModel?> addComment(String campaignId, String content) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase.from('campaign_comments').insert({
        'campaign_id': campaignId,
        'user_id': currentUser.id,
        'content': content,
      }).select('''
        *,
        user:users(*)
      ''').single();

      return CommentModel.fromJson(response);
    } catch (e) {
      print('Error adding campaign comment: $e');
      return null;
    }
  }
}
