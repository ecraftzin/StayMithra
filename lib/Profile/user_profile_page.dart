import 'package:flutter/material.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/follow_request_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/chat_service.dart';
import 'package:staymitra/config/supabase_config.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:staymitra/models/post_model.dart';
import 'package:staymitra/models/campaign_model.dart';
import 'package:staymitra/ChatPage/real_chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  final CampaignService _campaignService = CampaignService();
  final FollowRequestService _followRequestService = FollowRequestService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  UserModel? _user;
  bool _isLoading = true;
  List<PostModel> _userPosts = [];
  List<CampaignModel> _userCampaigns = [];
  int _followersCount = 0;
  int _followingCount = 0;
  String _followStatus = 'not_following';

  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await _userService.getUserById(widget.userId);

      if (userProfile != null) {
        // Load user's posts and campaigns
        await _loadUserStats(widget.userId);

        // Load follower counts
        await _loadFollowerCounts(widget.userId);

        // Load follow status
        await _loadFollowStatus();

        if (mounted) {
          setState(() {
            _user = userProfile;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      final posts = await _postService.getUserPosts(userId);
      final campaigns = await _campaignService.getUserCampaigns(userId);

      if (mounted) {
        setState(() {
          _userPosts = posts;
          _userCampaigns = campaigns;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<void> _loadFollowerCounts(String userId) async {
    try {
      // Count followers (people who follow this user)
      final followersResponse = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId);

      // Count following (people this user follows)
      final followingResponse =
          await supabase.from('follows').select('id').eq('follower_id', userId);

      if (mounted) {
        setState(() {
          _followersCount = followersResponse.length;
          _followingCount = followingResponse.length;
        });
      }
    } catch (e) {
      print('Error loading follower counts: $e');
    }
  }

  Future<void> _loadFollowStatus() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.id != widget.userId) {
        final status = await _followRequestService.getFollowStatus(
          currentUser.id,
          widget.userId,
        );
        if (mounted) {
          setState(() {
            _followStatus = status;
          });
        }
      }
    } catch (e) {
      print('Error loading follow status: $e');
    }
  }

  String _getInitials() {
    if (_user?.fullName != null && _user!.fullName!.isNotEmpty) {
      return _user!.fullName![0].toUpperCase();
    } else if (_user?.username != null && _user!.username.isNotEmpty) {
      return _user!.username[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  List<Widget> _buildAppBarActions() {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.id == widget.userId) {
      return [];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ElevatedButton(
          onPressed: _handleFollowAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getFollowButtonColor(),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(_getFollowButtonText()),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ElevatedButton(
          onPressed: _startChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF007F8C),
            side: const BorderSide(color: Color(0xFF007F8C)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Message'),
        ),
      ),
    ];
  }

  String _getFollowButtonText() {
    switch (_followStatus) {
      case 'not_following':
        return 'Follow';
      case 'requested':
        return 'Requested';
      case 'following':
      case 'mutual':
        return 'Following';
      case 'followed_by':
        return 'Follow';
      default:
        return 'Follow';
    }
  }

  Color _getFollowButtonColor() {
    switch (_followStatus) {
      case 'not_following':
      case 'followed_by':
        return const Color(0xFF007F8C);
      case 'requested':
        return Colors.orange;
      case 'following':
      case 'mutual':
        return Colors.grey;
      default:
        return const Color(0xFF007F8C);
    }
  }

  Future<void> _handleFollowAction() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Prevent users from following themselves
    if (currentUser.id == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot follow yourself'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success = false;
    String message = '';

    try {
      switch (_followStatus) {
        case 'not_following':
        case 'followed_by':
          success =
              await _followRequestService.sendFollowRequest(widget.userId);
          if (success) {
            message = 'Follow request sent!';
            setState(() => _followStatus = 'requested');
          } else {
            message = 'Failed to send follow request';
          }
          break;

        case 'requested':
          success =
              await _followRequestService.cancelFollowRequest(widget.userId);
          message =
              success ? 'Follow request cancelled' : 'Failed to cancel request';
          if (success) setState(() => _followStatus = 'not_following');
          break;

        case 'following':
        case 'mutual':
          success = await _followRequestService.unfollowUser(widget.userId);
          message =
              success ? 'Unfollowed ${_user?.username}' : 'Failed to unfollow';
          if (success) setState(() => _followStatus = 'not_following');
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _user == null) return;

    try {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealChatScreen(
              peerId: widget.userId,
              peerName: _user!.fullName ?? _user!.username ?? 'Unknown User',
              peerAvatar: _user!.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.userName ?? 'Profile'),
          backgroundColor: const Color(0xFF007F8C),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF007F8C),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF007F8C),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(screenWidth, screenHeight),
              ),
              actions: _buildAppBarActions(),
            ),
          ];
        },
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(),
                  _buildCampaignsGrid(),
                  _buildAllContentGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(double screenWidth, double screenHeight) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF007F8C), Color(0xFF005A6B)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.05),
            // Profile Picture
            CircleAvatar(
              radius: screenWidth * 0.12,
              backgroundImage: _user?.avatarUrl != null
                  ? NetworkImage(_user!.avatarUrl!)
                  : null,
              child: _user?.avatarUrl == null
                  ? Text(
                      _getInitials(),
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(height: screenHeight * 0.02),
            // Name and Username
            Text(
              _user?.fullName ?? _user?.username ?? 'User',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_user?.bio != null && _user!.bio!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  _user!.bio!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            // Stats Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Posts', '${_userPosts.length}'),
                  SizedBox(width: screenWidth * 0.08),
                  _buildStatColumn('Campaigns', '${_userCampaigns.length}'),
                  SizedBox(width: screenWidth * 0.08),
                  _buildStatColumn('Followers', '$_followersCount'),
                  SizedBox(width: screenWidth * 0.08),
                  _buildStatColumn('Following', '$_followingCount'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF007F8C),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF007F8C),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Campaigns'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildContentTile(post, true);
      },
    );
  }

  Widget _buildCampaignsGrid() {
    if (_userCampaigns.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No campaigns yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _userCampaigns.length,
      itemBuilder: (context, index) {
        final campaign = _userCampaigns[index];
        return _buildContentTile(campaign, false);
      },
    );
  }

  Widget _buildAllContentGrid() {
    final allContent = <dynamic>[..._userPosts, ..._userCampaigns];
    allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allContent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No content yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: allContent.length,
      itemBuilder: (context, index) {
        final item = allContent[index];
        final isPost = item is PostModel;
        return _buildContentTile(item, isPost);
      },
    );
  }

  Widget _buildContentTile(dynamic item, bool isPost) {
    final imageUrls = isPost ? item.imageUrls : item.imageUrls;
    final videoUrls = isPost ? item.videoUrls : item.videoUrls;
    final hasMedia =
        (imageUrls?.isNotEmpty ?? false) || (videoUrls?.isNotEmpty ?? false);

    return GestureDetector(
      onTap: () => _showContentDetail(item, isPost),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasMedia) ...[
              if (imageUrls?.isNotEmpty ?? false)
                CachedNetworkImage(
                  imageUrl: imageUrls!.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                )
              else if (videoUrls?.isNotEmpty ?? false)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ] else
              Container(
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    isPost ? Icons.photo : Icons.campaign,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                ),
              ),
            // Content type indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isPost ? Icons.photo : Icons.campaign,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentDetail(dynamic item, bool isPost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPost ? 'Post' : 'Campaign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title ?? 'No title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(item.description ?? 'No description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
