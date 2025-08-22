import 'package:flutter/material.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/chat_service.dart';
import 'package:staymitra/services/follow_request_service.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:staymitra/models/chat_model.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/config/supabase_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:staymitra/ChatPage/real_chat_screen.dart';
import 'package:staymitra/Profile/user_profile_page.dart';

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

  // Track follow status for each user
  final Map<String, String> _followStatuses = {}; // userId -> status
  final Map<String, bool> _followLoadingStates = {}; // userId -> isLoading

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh follow statuses when returning to this page
    _refreshAllFollowStatuses();
  }

  void _refreshAllFollowStatuses() {
    // Refresh follow status for search results
    for (final user in _searchResults) {
      _checkFollowStatus(user.id);
    }
    // Refresh follow status for recent users
    for (final user in _recentUsers) {
      _checkFollowStatus(user.id);
    }
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

        if (mounted && results.length >= 2) {
          setState(() {
            _recentChats = results[0] as List<ChatModel>;
            _recentUsers = results[1] as List<UserModel>;
          });
        }

        // Check follow status for recent users
        for (final user in _recentUsers) {
          _checkFollowStatus(user.id);
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

      // Check follow status for each user
      for (final user in results) {
        _checkFollowStatus(user.id);
      }
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
      // Check if both users follow each other
      final currentUserStatus = await _followRequestService.getFollowStatus(
        currentUser.id,
        user.id,
      );
      final otherUserStatus = await _followRequestService.getFollowStatus(
        user.id,
        currentUser.id,
      );

      // Check if there's any follow relationship (one-way follow allows chat)
      final canChat = currentUserStatus != 'not_following' &&
              currentUserStatus != 'requested' ||
          otherUserStatus != 'not_following' && otherUserStatus != 'requested';

      if (!canChat) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You need to follow each other to start chatting'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create or get existing chat
      final chat = await _chatService.createOrGetChat(
        currentUser.id,
        user.id,
      );

      if (chat != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealChatScreen(
              peerId: user.id,
              peerName: user.fullName ?? user.username,
              peerAvatar: user.avatarUrl,
            ),
          ),
        );
        // Refresh follow status when returning from chat
        if (mounted) {
          _checkFollowStatus(user.id);
        }
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

  Future<void> _checkFollowStatus(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Check outgoing status (current user -> target user)
      final outgoingStatus = await _followRequestService.getFollowStatus(
        currentUser.id,
        userId,
      );

      // Check incoming status (target user -> current user)
      final incomingStatus = await _followRequestService.getFollowStatus(
        userId,
        currentUser.id,
      );

      String finalStatus = outgoingStatus;

      // If there's an incoming request, prioritize showing "Accept Request"
      if (incomingStatus == 'requested') {
        finalStatus = 'incoming_request';
      }

      if (mounted) {
        setState(() {
          _followStatuses[userId] = finalStatus;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _handleFollowAction(UserModel user) async {
    if (_followLoadingStates[user.id] == true) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Prevent users from following themselves
    if (currentUser.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot follow yourself'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _followLoadingStates[user.id] = true);

    try {
      final currentStatus = _followStatuses[user.id] ?? 'not_following';
      bool success = false;
      String message = '';

      switch (currentStatus) {
        case 'not_following':
          // First check current status to avoid unnecessary requests
          final currentStatus = await _followRequestService.getFollowStatus(
            _authService.currentUser!.id,
            user.id,
          );

          if (currentStatus == 'following' ||
              currentStatus == 'mutual' ||
              currentStatus == 'followed_by') {
            message = 'You are already connected!';
            _followStatuses[user.id] = currentStatus;
            success = true;
          } else if (currentStatus == 'requested') {
            message = 'Follow request already sent';
            _followStatuses[user.id] = 'requested';
            success = true;
          } else {
            success = await _followRequestService.sendFollowRequest(user.id);
            if (success) {
              message = 'Follow request sent!';
              _followStatuses[user.id] = 'requested';
            } else {
              message = 'Failed to send follow request';
            }
          }
          break;

        case 'requested':
          success = await _followRequestService.cancelFollowRequest(user.id);
          message =
              success ? 'Follow request cancelled' : 'Failed to cancel request';
          if (success) _followStatuses[user.id] = 'not_following';
          break;

        case 'incoming_request':
          // Accept the incoming follow request
          // First, find the request ID
          final requestId = await _getIncomingRequestId(user.id);
          if (requestId != null) {
            success =
                await _followRequestService.acceptFollowRequest(requestId);
            message = success
                ? 'Follow request accepted!'
                : 'Failed to accept request';
            if (success) {
              // Check the new status after accepting
              _checkFollowStatus(user.id);
            }
          } else {
            message = 'Request not found';
          }
          break;

        case 'followed_by':
          // User follows back
          success = await _followRequestService.sendFollowRequest(user.id);
          if (success) {
            message = 'Follow request sent!';
            _followStatuses[user.id] = 'mutual'; // Now mutual follow
          } else {
            message = 'Failed to send follow request';
          }
          break;

        case 'following':
        case 'mutual':
          success = await _followRequestService.unfollowUser(user.id);
          message =
              success ? 'Unfollowed ${user.username}' : 'Failed to unfollow';
          if (success) _followStatuses[user.id] = 'not_following';
          break;
      }

      if (mounted) {
        setState(() => _followLoadingStates[user.id] = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _followLoadingStates[user.id] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _getIncomingRequestId(String fromUserId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await supabase
          .from('follow_requests')
          .select('id')
          .eq('requester_id', fromUserId)
          .eq('requested_id', currentUser.id)
          .eq('status', 'pending')
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      print('Error getting incoming request ID: $e');
      return null;
    }
  }

  String _getFollowButtonText(String userId) {
    final status = _followStatuses[userId] ?? 'not_following';
    switch (status) {
      case 'not_following':
        return 'Follow';
      case 'requested':
        return 'Requested';
      case 'incoming_request':
        return 'Accept';
      case 'following':
        return 'Following';
      case 'mutual':
        return 'Following';
      case 'followed_by':
        return 'Follow';
      default:
        return 'Follow';
    }
  }

  Color _getFollowButtonColor(String userId) {
    final status = _followStatuses[userId] ?? 'not_following';
    switch (status) {
      case 'not_following':
        return const Color(0xFF007F8C);
      case 'requested':
        return Colors.orange;
      case 'incoming_request':
        return Colors.green;
      case 'following':
      case 'mutual':
        return Colors.grey;
      case 'followed_by':
        return Colors.blue;
      default:
        return const Color(0xFF007F8C);
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
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // Fallback to main page
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
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
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: user.id,
                userName: user.username,
              ),
            ),
          );
        },
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundImage: user.avatarUrl != null
              ? CachedNetworkImageProvider(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
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
        trailing: _authService.currentUser?.id == user.id
            ? null // Hide follow button for current user
            : SizedBox(
                width: screenWidth * 0.2,
                child: ElevatedButton(
                  onPressed: _followLoadingStates[user.id] == true
                      ? null
                      : () => _handleFollowAction(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getFollowButtonColor(user.id),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenWidth * 0.01,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    elevation: 0,
                    minimumSize: Size(screenWidth * 0.18, screenWidth * 0.08),
                  ),
                  child: _followLoadingStates[user.id] == true
                      ? SizedBox(
                          width: screenWidth * 0.03,
                          height: screenWidth * 0.03,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _getFollowButtonText(user.id),
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
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
                  otherUser.username.isNotEmpty
                      ? otherUser.username[0].toUpperCase()
                      : '?',
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
            fontWeight:
                chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          chat.lastMessage?.content ?? 'Start a conversation',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
            fontWeight:
                chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: chat.unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () async {
          // Mark messages as read when opening chat
          final currentUser = _authService.currentUser;
          if (currentUser != null) {
            print('DEBUG: About to mark messages as read for chat ${chat.id}');
            await _chatService.markMessagesAsRead(chat.id, currentUser.id);
            print(
                'DEBUG: Finished marking messages as read, refreshing chat list');
            // Immediately refresh the chat list to update badges
            if (mounted) {
              await _loadInitialData();
            }
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RealChatScreen(
                  peerId: otherUser.id,
                  peerName: otherUser.fullName ?? otherUser.username,
                  peerAvatar: otherUser.avatarUrl,
                ),
              ),
            ).then((_) {
              // Refresh chat list again when returning from chat
              if (mounted) {
                _loadInitialData();
              }
            });
          }
        },
      ),
    );
  }
}
