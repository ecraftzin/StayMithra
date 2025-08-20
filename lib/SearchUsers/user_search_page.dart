import 'package:flutter/material.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/chat_service.dart';
import 'package:staymitra/services/follow_request_service.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:staymitra/models/chat_model.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:staymitra/ChatPage/real_chat_screen.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FollowRequestService _followRequestService = FollowRequestService();

  List<UserModel> _searchResults = [];
  List<ChatModel> _recentChats = [];
  List<UserModel> _recentUsers = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Load recent chats and recent users in parallel
        final results = await Future.wait([
          _chatService.getUserChats(currentUser.id),
          _userService.getRecentUsers(limit: 10),
        ]);

        setState(() {
          _recentChats = results[0] as List<ChatModel>;
          _recentUsers = results[1] as List<UserModel>;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startChat(UserModel user) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Create or get existing chat
      final chat = await _chatService.createOrGetChat(
        currentUser.id,
        user.id,
      );

      if (chat != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealChatScreen(
              peerId: user.id,
              peerName: user.fullName ?? user.username,
              peerAvatar: user.avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().contains('must follow each other')
                        ? 'You need to follow each other to start a chat'
                        : 'Error starting chat: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: e.toString().contains('must follow each other')
                ? Colors.orange
                : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Search Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Search Users',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007F8C),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // Search Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Search by username, email, or name...',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(screenWidth, screenHeight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(double screenWidth, double screenHeight) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults(screenWidth, screenHeight);
    } else {
      return _buildInitialContent(screenWidth, screenHeight);
    }
  }

  Widget _buildSearchResults(double screenWidth, double screenHeight) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: screenWidth * 0.2,
              color: Colors.grey,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user, screenWidth);
      },
    );
  }

  Widget _buildInitialContent(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Chats Section
          if (_recentChats.isNotEmpty) ...[
            Text(
              'Recent Chats',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007F8C),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            ...(_recentChats.map((chat) => _buildChatTile(chat, screenWidth))),
            SizedBox(height: screenHeight * 0.03),
          ],

          // Recent Users Section
          if (_recentUsers.isNotEmpty) ...[
            Text(
              'Recently Joined',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007F8C),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            ...(_recentUsers.map((user) => _buildUserTile(user, screenWidth))),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _startChat(user),
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundImage: user.avatarUrl != null
              ? CachedNetworkImageProvider(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName ?? user.username,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(
                user.bio!,
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat, double screenWidth) {
    final otherUser = chat.otherUser;
    if (otherUser == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundImage: otherUser.avatarUrl != null
              ? CachedNetworkImageProvider(otherUser.avatarUrl!)
              : null,
          child: otherUser.avatarUrl == null
              ? Text(
                  otherUser.username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          otherUser.fullName ?? otherUser.username,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          chat.lastMessage?.content ?? 'Start a conversation',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RealChatScreen(
                peerId: otherUser.id,
                peerName: otherUser.fullName ?? otherUser.username,
                peerAvatar: otherUser.avatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
