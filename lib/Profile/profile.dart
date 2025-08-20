import 'package:flutter/material.dart';
import 'package:staymitra/Profile/profileedit.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/follow_service.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:staymitra/models/post_model.dart';
import 'package:staymitra/models/campaign_model.dart';
import 'package:staymitra/widgets/video_player_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  final CampaignService _campaignService = CampaignService();
  final FollowService _followService = FollowService();

  UserModel? _currentUser;
  bool _isLoading = true;
  List<PostModel> _userPosts = [];
  List<CampaignModel> _userCampaigns = [];

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
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userProfile = await _userService.getUserById(currentUser.id);

        // Load user's posts and campaigns count
        await _loadUserStats(currentUser.id);

        setState(() {
          _currentUser = userProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      // Load user's posts and campaigns
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  String _getInitials() {
    if (_currentUser?.fullName != null && _currentUser!.fullName!.isNotEmpty) {
      return _currentUser!.fullName![0].toUpperCase();
    } else if (_currentUser?.username != null &&
        _currentUser!.username.isNotEmpty) {
      return _currentUser!.username[0].toUpperCase();
    } else {
      return 'U';
    }
  }

  Widget _buildUserContentItem(dynamic item, double screenWidth) {
    final isPost = item.runtimeType.toString().contains('Post');
    final title =
        isPost ? (item.content ?? 'Post') : (item.title ?? 'Campaign');
    final subtitle = isPost ? 'Post' : 'Campaign';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPost ? Colors.blue : const Color(0xFF007F8C),
          child: Icon(
            isPost ? Icons.post_add : Icons.campaign,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Navigate to edit page
              print('Edit ${isPost ? 'post' : 'campaign'}: ${item.id}');
            } else if (value == 'delete') {
              // TODO: Delete item
              print('Delete ${isPost ? 'post' : 'campaign'}: ${item.id}');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
              actions: [
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );

                    // Refresh profile data if edit was successful
                    if (result == true) {
                      _loadUserProfile();
                    }
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
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
                  _buildMixedGrid(),
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
              backgroundImage: _currentUser?.avatarUrl != null
                  ? NetworkImage(_currentUser!.avatarUrl!)
                  : null,
              child: _currentUser?.avatarUrl == null
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
              _currentUser?.fullName ?? _currentUser?.username ?? 'User',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_currentUser?.bio != null && _currentUser!.bio!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  _currentUser!.bio!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', '${_userPosts.length}'),
                _buildStatColumn('Campaigns', '${_userCampaigns.length}'),
                _buildStatColumn(
                    'Total', '${_userPosts.length + _userCampaigns.length}'),
              ],
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
        indicatorColor: const Color(0xFF007F8C),
        labelColor: const Color(0xFF007F8C),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
          Tab(icon: Icon(Icons.campaign), text: 'Campaigns'),
          Tab(icon: Icon(Icons.apps), text: 'All'),
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to create your first post',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildGridItem(post, true);
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first campaign to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userCampaigns.length,
      itemBuilder: (context, index) {
        final campaign = _userCampaigns[index];
        return _buildGridItem(campaign, false);
      },
    );
  }

  Widget _buildMixedGrid() {
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start creating posts and campaigns',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: allContent.length,
      itemBuilder: (context, index) {
        final item = allContent[index];
        final isPost = item is PostModel;
        return _buildGridItem(item, isPost);
      },
    );
  }

  Widget _buildGridItem(dynamic item, bool isPost) {
    final imageUrls = isPost ? item.imageUrls : item.imageUrls;
    final videoUrls = isPost ? item.videoUrls : item.videoUrls;
    final hasMedia = imageUrls.isNotEmpty || videoUrls.isNotEmpty;

    return GestureDetector(
      onTap: () => _showContentDetail(item, isPost),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasMedia) ...[
              if (imageUrls.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrls.first,
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
              else if (videoUrls.isNotEmpty)
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
                    isPost ? Icons.text_fields : Icons.campaign,
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
            // Edit/Delete options
            Positioned(
              bottom: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 16,
                ),
                onSelected: (value) =>
                    _handleContentAction(value, item, isPost),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 16),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentDetail(dynamic item, bool isPost) {
    // TODO: Navigate to detailed view of post/campaign
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPost ? 'Post Details' : 'Campaign Details'),
        content: Text(isPost ? item.content : item.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleContentAction(String action, dynamic item, bool isPost) {
    switch (action) {
      case 'edit':
        _editContent(item, isPost);
        break;
      case 'delete':
        _deleteContent(item, isPost);
        break;
      case 'share':
        _shareContent(item, isPost);
        break;
    }
  }

  void _editContent(dynamic item, bool isPost) {
    // TODO: Navigate to edit page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${isPost ? 'post' : 'campaign'}: ${item.id}'),
      ),
    );
  }

  void _deleteContent(dynamic item, bool isPost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isPost ? 'Post' : 'Campaign'}'),
        content: Text(
            'Are you sure you want to delete this ${isPost ? 'post' : 'campaign'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(item, isPost);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(dynamic item, bool isPost) async {
    try {
      if (isPost) {
        await _postService.deletePost(item.id, _currentUser!.id);
        setState(() {
          _userPosts.removeWhere((post) => post.id == item.id);
        });
      } else {
        await _campaignService.deleteCampaign(item.id, _currentUser!.id);
        setState(() {
          _userCampaigns.removeWhere((campaign) => campaign.id == item.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${isPost ? 'Post' : 'Campaign'} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ${isPost ? 'post' : 'campaign'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareContent(dynamic item, bool isPost) async {
    try {
      final String shareText = isPost
          ? 'Check out this post: ${item.content}'
          : 'Join this campaign: ${item.title} - ${item.description}';

      final String shareUrl =
          'https://staymitra.app/${isPost ? 'post' : 'campaign'}/${item.id}';

      await Share.share('$shareText\n\n$shareUrl');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
