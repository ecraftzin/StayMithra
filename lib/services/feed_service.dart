import '../services/post_service.dart';
import '../services/campaign_service.dart';
import '../models/feed_item_model.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  final PostService _postService = PostService();
  final CampaignService _campaignService = CampaignService();

  // Get unified feed with both posts and campaigns
  Future<List<FeedItem>> getFeed({int limit = 20, int offset = 0}) async {
    try {
      // Get posts and campaigns in parallel
      final results = await Future.wait([
        _postService.getAllPosts(limit: limit ~/ 2, offset: offset ~/ 2),
        _campaignService.getAllCampaigns(
            limit: limit ~/ 2, offset: offset ~/ 2),
      ]);

      final posts = results[0] as List<dynamic>;
      final campaigns = results[1] as List<dynamic>;

      // Convert to feed items
      final feedItems = <FeedItem>[];

      // Add posts
      for (final post in posts) {
        feedItems.add(FeedItem.fromPost(post));
      }

      // Add campaigns
      for (final campaign in campaigns) {
        feedItems.add(FeedItem.fromCampaign(campaign));
      }

      // Sort by creation date (newest first)
      feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return feedItems.take(limit).toList();
    } catch (e) {
      print('Error getting feed: $e');
      return [];
    }
  }

  // Create sample posts for testing
  Future<void> createSamplePosts(String userId) async {
    final samplePosts = [
      {
        'content':
            'Just had an amazing hiking experience in the Western Ghats! The views were absolutely breathtaking. Who else loves adventure travel? 🏔️ #hiking #adventure #nature',
        'location': 'Western Ghats, India',
      },
      {
        'content':
            'Cooking some delicious South Indian breakfast today! Nothing beats fresh dosa and sambar on a Sunday morning. What\'s your favorite breakfast? 🥞 #food #southindian #breakfast',
        'location': 'Bangalore, India',
      },
      {
        'content':
            'Beautiful sunset at Marina Beach! Chennai never fails to amaze me with its coastal beauty. Perfect evening for a walk by the sea. 🌅 #sunset #chennai #beach',
        'location': 'Marina Beach, Chennai',
      },
      {
        'content':
            'Working on some exciting new projects! Technology is evolving so fast, and I love being part of this journey. What tech trends are you most excited about? 💻 #technology #innovation',
        'location': 'Hyderabad, India',
      },
      {
        'content':
            'Weekend vibes at the local farmers market! Fresh fruits, vegetables, and so much local culture. Supporting local businesses feels great! 🥕🍅 #local #farmers #weekend',
        'location': 'Pune, India',
      },
    ];

    for (final postData in samplePosts) {
      await _postService.createPost(
        userId: userId,
        content: postData['content']!,
        location: postData['location'],
      );

      // Add a small delay to ensure different timestamps
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // Create sample campaigns for testing
  Future<void> createSampleCampaigns(String userId) async {
    final sampleCampaigns = [
      {
        'title': 'Weekend Trek to Nandi Hills',
        'description':
            'Join us for an exciting weekend trek to Nandi Hills! Perfect for beginners and experienced trekkers alike. We\'ll start early morning and enjoy the sunrise from the top. Includes transportation, breakfast, and guide.',
        'location': 'Nandi Hills, Karnataka',
        'category': 'Adventure',
        'price': 1500.0,
        'maxParticipants': 25,
      },
      {
        'title': 'Photography Workshop - Street Photography',
        'description':
            'Learn the art of street photography with professional photographers! This hands-on workshop covers composition, lighting, and storytelling through images. All skill levels welcome. Camera equipment provided if needed.',
        'location': 'Commercial Street, Bangalore',
        'category': 'Workshop',
        'price': 2000.0,
        'maxParticipants': 15,
      },
      {
        'title': 'Beach Cleanup Drive - Marina Beach',
        'description':
            'Let\'s come together to clean our beautiful Marina Beach! Join this environmental initiative to make our beaches cleaner and safer for marine life. Refreshments and cleanup materials provided.',
        'location': 'Marina Beach, Chennai',
        'category': 'Social',
        'maxParticipants': 50,
      },
      {
        'title': 'Food Festival - Taste of South India',
        'description':
            'Experience the diverse flavors of South Indian cuisine! Local chefs will showcase traditional dishes from different states. Live cooking demonstrations, food stalls, and cultural performances.',
        'location': 'Phoenix MarketCity, Chennai',
        'category': 'Food',
        'price': 500.0,
        'maxParticipants': 100,
      },
    ];

    for (final campaignData in sampleCampaigns) {
      await _campaignService.createCampaign(
        userId: userId,
        title: campaignData['title']! as String,
        description: campaignData['description']! as String,
        location: campaignData['location'] as String?,
        category: campaignData['category'] as String?,
        price: campaignData['price'] as double?,
        maxParticipants: campaignData['maxParticipants'] as int?,
        startDate: DateTime.now()
            .add(Duration(days: (campaignData.hashCode % 30) + 1)),
      );

      // Add a small delay to ensure different timestamps
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
