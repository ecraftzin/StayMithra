import 'package:flutter/material.dart';
import 'package:staymitra/Profile/profileedit.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/follow_service.dart';
import 'package:staymitra/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  final CampaignService _campaignService = CampaignService();
  final FollowService _followService = FollowService();
  UserModel? _currentUser;
  bool _isLoading = true;
  int _postCount = 0;
  int _campaignCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  List<dynamic> _userContent = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
      // Load posts count
      final posts = await _postService.getUserPosts(userId);
      _postCount = posts.length;

      // Load campaigns count
      final campaigns = await _campaignService.getUserCampaigns(userId);
      _campaignCount = campaigns.length;

      // Combine posts and campaigns for display
      _userContent = [...posts, ...campaigns];

      // Load actual followers/following counts from database
      _followersCount = await _followService.getFollowersCount(userId);
      _followingCount = await _followService.getFollowingCount(userId);
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
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: screenHeight * 0.35, // responsive height
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF007F99), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _signOut,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                CircleAvatar(
                  radius: screenWidth * 0.18, // responsive avatar size
                  backgroundImage: _currentUser?.avatarUrl != null
                      ? NetworkImage(_currentUser!.avatarUrl!)
                      : null,
                  backgroundColor: const Color(0xFF007F8C),
                  child: _currentUser?.avatarUrl == null
                      ? Text(
                          _getInitials(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  _currentUser?.fullName ?? _currentUser?.username ?? 'User',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF015F6B),
                  ),
                ),
                Text(
                  _currentUser?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF015F6B),
                  ),
                ),
                if (_currentUser?.bio != null &&
                    _currentUser!.bio!.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.01),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      _currentUser!.bio!,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ProfileStat(
                            title: "Following", count: "$_followingCount"),
                        const VerticalDivider(thickness: 1, color: Colors.grey),
                        ProfileStat(
                            title: "Posts",
                            count: "${_postCount + _campaignCount}"),
                        const VerticalDivider(thickness: 1, color: Colors.grey),
                        ProfileStat(
                            title: "Followers", count: "$_followersCount"),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // My Posts and Campaigns Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Posts & Campaigns',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF015F6B),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: _userContent.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.post_add,
                                      size: screenWidth * 0.15,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Your posts and campaigns will appear here',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _userContent.length,
                                itemBuilder: (context, index) {
                                  final item = _userContent[index];
                                  return _buildUserContentItem(
                                      item, screenWidth);
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
                ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF015F6B),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String title;
  final String count;

  const ProfileStat({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w500, fontSize: screenWidth * 0.04),
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          count,
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
