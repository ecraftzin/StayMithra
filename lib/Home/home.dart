import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:staymitra/SearchUsers/user_search_page.dart';
import 'package:staymitra/Posts/create_post_page.dart';
import 'package:staymitra/services/feed_service.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/debug_service.dart';
import 'package:staymitra/services/chat_service.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:staymitra/Profile/user_profile_page.dart';
import 'package:staymitra/models/feed_item_model.dart';
import 'package:staymitra/ChatPage/real_chat_screen.dart';
import 'package:staymitra/widgets/video_player_widget.dart';
import 'package:staymitra/Comments/comments_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class StaymithraHomePage extends StatefulWidget {
  const StaymithraHomePage({super.key});

  @override
  State<StaymithraHomePage> createState() => _StaymithraHomePageState();
}

class _StaymithraHomePageState extends State<StaymithraHomePage> {
  final FeedService _feedService = FeedService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasCreatedSampleData = false;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _createSampleDataIfNeeded();
    _loadUnreadChatCount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _createSampleDataIfNeeded() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null && !_hasCreatedSampleData) {
      // Test Supabase connection and storage
      await DebugService().testSupabaseConnection();
      await DebugService().testImageUpload();

      // Only create sample campaigns (not posts without images)
      await _feedService.createSampleCampaigns(currentUser.id);
      if (mounted) {
        setState(() => _hasCreatedSampleData = true);
      }
      // Refresh feed after creating sample data
      _loadFeed(refresh: true);
    }
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh && mounted) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _feedItems.clear();
      });
    }

    try {
      final feedItems = await _feedService.getFeed(
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _feedItems = feedItems;
          } else {
            _feedItems.addAll(feedItems);
          }
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading feed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoadingMore) return;

    if (mounted) {
      setState(() => _isLoadingMore = true);
    }
    await _loadFeed();
  }

  Future<void> _loadUnreadChatCount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final count = await _chatService.getUnreadMessageCount(currentUser.id);
        if (mounted) {
          setState(() => _unreadChatCount = count);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result == true) {
      // Refresh feed if a new post was created
      _loadFeed(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'staymithra',
          style: TextStyle(
            color: const Color(0xFF007F8C),
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserSearchPage(),
                    ),
                  );
                  // Refresh chat count when returning from search/chat page
                  if (mounted) {
                    await _loadUnreadChatCount();
                  }
                },
                icon: Icon(
                  Icons.message_outlined,
                  color: Colors.black,
                  size: screenWidth * 0.06,
                ),
              ),
              if (_unreadChatCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: screenWidth * 0.025),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "home_fab",
        onPressed: _navigateToCreatePost,
        backgroundColor: const Color(0xFF007F8C),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadFeed(refresh: true),
              child: _feedItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add,
                            size: screenWidth * 0.2,
                            color: Colors.grey,
                          ),
                          SizedBox(height: screenWidth * 0.04),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            'Tap the + button to create your first post',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      itemCount: _feedItems.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _feedItems.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final feedItem = _feedItems[index];
                        return FeedItemWidget(
                          feedItem: feedItem,
                          screenWidth: screenWidth,
                          onLoadMore: index == _feedItems.length - 3
                              ? _loadMoreFeed
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class FeedItemWidget extends StatefulWidget {
  final FeedItem feedItem;
  final double screenWidth;
  final VoidCallback? onLoadMore;

  const FeedItemWidget({
    super.key,
    required this.feedItem,
    required this.screenWidth,
    this.onLoadMore,
  });

  @override
  State<FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends State<FeedItemWidget> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final CampaignService _campaignService = CampaignService();
  bool _isLiked = false;
  bool _isLiking = false;
  int _currentLikeCount = 0;
  bool _isJoined = false;
  bool _isJoining = false;
  int _currentParticipantCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize like count and participant count
    if (widget.feedItem.type == FeedItemType.post) {
      _currentLikeCount = widget.feedItem.post?.likesCount ?? 0;
    } else if (widget.feedItem.type == FeedItemType.campaign) {
      _currentLikeCount = widget.feedItem.campaign?.likesCount ?? 0;
      _currentParticipantCount =
          widget.feedItem.campaign?.currentParticipants ?? 0;
      _checkIfJoined();
    }
    _checkIfLiked();

    // Trigger load more when this widget is created near the end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadMore?.call();
    });
  }

  Future<void> _checkIfLiked() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      bool liked = false;

      if (widget.feedItem.type == FeedItemType.post &&
          widget.feedItem.post != null) {
        liked = await _postService.hasUserLikedPost(
            widget.feedItem.post!.id, currentUser.id);
      } else if (widget.feedItem.type == FeedItemType.campaign &&
          widget.feedItem.campaign != null) {
        liked = await _campaignService.hasUserLikedCampaign(
            widget.feedItem.campaign!.id, currentUser.id);
      }

      if (mounted) {
        setState(() => _isLiked = liked);
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _checkIfJoined() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null ||
        widget.feedItem.type != FeedItemType.campaign ||
        widget.feedItem.campaign == null) {
      return;
    }

    try {
      final joined = await _campaignService.hasUserJoinedCampaign(
          widget.feedItem.campaign!.id, currentUser.id);

      if (mounted) {
        setState(() => _isJoined = joined);
      }
    } catch (e) {
      print('Error checking join status: $e');
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _isLiking) return;

    if (mounted) {
      setState(() => _isLiking = true);
    }

    try {
      int newLikeCount;

      if (widget.feedItem.type == FeedItemType.post &&
          widget.feedItem.post != null) {
        // Handle post likes
        if (_isLiked) {
          newLikeCount = await _postService.unlikePost(
              widget.feedItem.post!.id, currentUser.id);
        } else {
          newLikeCount = await _postService.likePost(
              widget.feedItem.post!.id, currentUser.id);
        }
      } else if (widget.feedItem.type == FeedItemType.campaign &&
          widget.feedItem.campaign != null) {
        // Handle campaign likes
        if (_isLiked) {
          newLikeCount = await _campaignService.unlikeCampaign(
              widget.feedItem.campaign!.id, currentUser.id);
        } else {
          newLikeCount = await _campaignService.likeCampaign(
              widget.feedItem.campaign!.id, currentUser.id);
        }
      } else {
        return; // Invalid feed item type
      }

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _currentLikeCount = newLikeCount;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  Future<void> _toggleJoin() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null ||
        _isJoining ||
        widget.feedItem.type != FeedItemType.campaign ||
        widget.feedItem.campaign == null) {
      return;
    }

    if (mounted) {
      setState(() => _isJoining = true);
    }

    try {
      if (_isJoined) {
        // Leave campaign
        final success = await _campaignService.leaveCampaign(
            widget.feedItem.campaign!.id, currentUser.id);
        if (success && mounted) {
          setState(() {
            _isJoined = false;
            _currentParticipantCount = (_currentParticipantCount - 1)
                .clamp(0, double.infinity)
                .toInt();
          });
        }
      } else {
        // Join campaign
        final newCount = await _campaignService.joinCampaignWithCount(
            widget.feedItem.campaign!.id, currentUser.id);
        if (newCount != null && mounted) {
          setState(() {
            _isJoined = true;
            _currentParticipantCount = newCount;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign is full or error occurred')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _startChat() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final otherUserId = widget.feedItem.userId;
    final otherUser = widget.feedItem.user;

    if (otherUserId == currentUser.id) return; // Don't chat with yourself

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealChatScreen(
          peerId: otherUserId,
          peerName: otherUser?.fullName ?? otherUser?.username ?? 'User',
          peerAvatar: otherUser?.avatarUrl,
        ),
      ),
    );
  }

  Widget _buildMediaSection(double screenWidth) {
    final allMediaUrls = <Map<String, dynamic>>[];

    // Add images
    for (final imageUrl in widget.feedItem.imageUrls) {
      if (imageUrl.isNotEmpty &&
          imageUrl.startsWith('https://rssnqbqbrejnjeiukrdr.supabase.co') &&
          !imageUrl.contains('blob:')) {
        allMediaUrls.add({'type': 'image', 'url': imageUrl});
      }
    }

    // Add videos
    for (final videoUrl in widget.feedItem.videoUrls) {
      if (videoUrl.isNotEmpty &&
          videoUrl.startsWith('https://rssnqbqbrejnjeiukrdr.supabase.co') &&
          !videoUrl.contains('blob:')) {
        allMediaUrls.add({'type': 'video', 'url': videoUrl});
      }
    }

    if (allMediaUrls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: screenWidth * 0.8,
      child: PageView.builder(
        itemCount: allMediaUrls.length,
        itemBuilder: (context, index) {
          final media = allMediaUrls[index];
          final isVideo = media['type'] == 'video';

          return ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: isVideo
                ? VideoPlayerWidget(
                    videoUrl: media['url'],
                    autoPlay: true,
                    showControls: true,
                    looping: true,
                  )
                : (media['url'] != null &&
                        media['url'].toString().isNotEmpty &&
                        !media['url'].toString().contains('blob:'))
                    ? CachedNetworkImage(
                        imageUrl: media['url'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: screenWidth * 0.8,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: screenWidth * 0.8,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 50),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        height: screenWidth * 0.8,
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50),
                            SizedBox(height: 8),
                            Text(
                              'Invalid image URL',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }

  void _handleComment(FeedItem item) {
    // Get appropriate title/content for the comments page
    String contentTitle;
    if (item.type == FeedItemType.campaign && item.title != null) {
      contentTitle = item.title!;
    } else {
      contentTitle = item.content;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(
          contentId: item.id,
          contentType: item.type == FeedItemType.post ? 'post' : 'campaign',
          contentTitle: contentTitle,
        ),
      ),
    );
  }

  void _handleShare(FeedItem feedItem) async {
    try {
      String shareText;
      String shareUrl;

      if (feedItem.type == FeedItemType.post) {
        shareText = 'Check out this post: ${feedItem.content}';
        shareUrl = 'https://staymitra.app/post/${feedItem.id}';
      } else {
        shareText =
            'Join this campaign: ${feedItem.title} - ${feedItem.content}';
        shareUrl = 'https://staymitra.app/campaign/${feedItem.id}';
      }

      await Share.share('$shareText\n\n$shareUrl');

      // Track the share in the backend
      if (feedItem.type == FeedItemType.post) {
        await _postService.sharePost(
            feedItem.id, _authService.currentUser?.id ?? '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  void _navigateToUserProfile(UserModel? user) {
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(
          userId: user.id,
          userName: user.fullName ?? user.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedItem = widget.feedItem;
    final user = feedItem.user;
    final screenWidth = widget.screenWidth;
    final currentUser = _authService.currentUser;
    final isOwnContent = currentUser?.id == feedItem.userId;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: screenWidth * 0.025,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserProfile(user),
                  child: CircleAvatar(
                    radius: screenWidth * 0.055,
                    backgroundImage: user?.avatarUrl != null &&
                            user!.avatarUrl!.isNotEmpty &&
                            !user.avatarUrl!.contains('blob:')
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null ||
                            user!.avatarUrl!.isEmpty ||
                            user.avatarUrl!.contains('blob:')
                        ? Text(
                            (user?.username ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: screenWidth * 0.025),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _navigateToUserProfile(user),
                              child: Text(
                                user?.fullName ??
                                    user?.username ??
                                    'Unknown User',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Campaign indicator and chat button
                          if (feedItem.type == FeedItemType.campaign) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007F8C).withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(screenWidth * 0.02),
                              ),
                              child: Text(
                                'EVENT',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  color: const Color(0xFF007F8C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                          ],
                          // Chat button (only for other users' content)
                          if (!isOwnContent)
                            IconButton(
                              onPressed: _startChat,
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                color: const Color(0xFF007F8C),
                                size: screenWidth * 0.05,
                              ),
                            ),
                        ],
                      ),
                      if (feedItem.location != null)
                        Text(
                          feedItem.location!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        timeago.format(feedItem.createdAt),
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove edit options from home page - just show posts
              ],
            ),
          ),
          // Media (Images and Videos)
          if (feedItem.imageUrls.isNotEmpty || feedItem.videoUrls.isNotEmpty)
            _buildMediaSection(screenWidth),

          // Content
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title for campaigns
                if (feedItem.title != null) ...[
                  Text(
                    feedItem.title!,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                ],
                // Content/Description
                Text(
                  feedItem.content,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.04,
                  ),
                  maxLines: feedItem.type == FeedItemType.campaign ? 3 : null,
                  overflow: feedItem.type == FeedItemType.campaign
                      ? TextOverflow.ellipsis
                      : null,
                ),
                SizedBox(height: screenWidth * 0.025),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Like button (for both posts and campaigns)
                        IconButton(
                          onPressed: _toggleLike,
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey[600],
                            size: screenWidth * 0.06,
                          ),
                        ),
                        Text(
                          '$_currentLikeCount',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        // Comment button (for both posts and campaigns)
                        IconButton(
                          onPressed: () => _handleComment(feedItem),
                          icon: Icon(
                            Icons.comment_outlined,
                            color: Colors.grey[600],
                            size: screenWidth * 0.06,
                          ),
                        ),
                        Text(
                          '${feedItem.type == FeedItemType.post ? feedItem.post?.commentsCount ?? 0 : feedItem.campaign?.commentsCount ?? 0}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        // Join button for campaigns
                        if (feedItem.type == FeedItemType.campaign) ...[
                          ElevatedButton.icon(
                            onPressed: _isJoining ? null : _toggleJoin,
                            icon: Icon(
                              _isJoined ? Icons.check : Icons.add,
                              size: screenWidth * 0.04,
                            ),
                            label: Text(
                              _isJoined ? 'Joined' : 'Join',
                              style: TextStyle(fontSize: screenWidth * 0.035),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isJoined
                                  ? Colors.green
                                  : const Color(0xFF007F8C),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenWidth * 0.01,
                              ),
                              minimumSize:
                                  Size(screenWidth * 0.2, screenWidth * 0.08),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            '$_currentParticipantCount${feedItem.campaign?.maxParticipants != null ? '/${feedItem.campaign!.maxParticipants}' : ''}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          if (feedItem.campaign?.price != null) ...[
                            Icon(
                              Icons.currency_rupee,
                              color: const Color(0xFF007F8C),
                              size: screenWidth * 0.04,
                            ),
                            Text(
                              feedItem.campaign!.price!.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: const Color(0xFF007F8C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    // Share button
                    IconButton(
                      onPressed: () => _handleShare(feedItem),
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.grey[600],
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
