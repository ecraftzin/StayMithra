import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/follow_request_service.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';
import '../config/supabase_config.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final FollowRequestService _followRequestService = FollowRequestService();
  final AuthService _authService = AuthService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notifications = await _notificationService.getNotifications(
        limit: _pageSize,
        offset: 0,
      );

      print('DEBUG: Loaded ${notifications.length} notifications');
      for (final notification in notifications) {
        print(
            'DEBUG: Notification ${notification.id} - Type: ${notification.type}, Title: ${notification.title}, Data: ${notification.data}');
      }

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreNotifications = await _notificationService.getNotifications(
        limit: _pageSize,
        offset: (_currentPage + 1) * _pageSize,
      );

      if (mounted && moreNotifications.isNotEmpty) {
        setState(() {
          _notifications.addAll(moreNotifications);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _handleFollowRequest(String notificationId, bool accept) async {
    // Check if this notification has already been processed
    final notification =
        _notifications.firstWhere((n) => n.id == notificationId);
    if (notification.type == 'follow_accepted_by_you') {
      print('DEBUG: Notification already processed, ignoring');
      return;
    }

    // Remove notification immediately for better responsiveness
    if (mounted && accept) {
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
    }

    try {
      // Find the notification to get the actual follow request data
      final notification =
          _notifications.firstWhere((n) => n.id == notificationId);
      final requesterId = notification.data?['requester_id'] as String?;

      if (requesterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid request data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Find the actual follow request ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final followRequest = await supabase
          .from('follow_requests')
          .select('id')
          .eq('requester_id', requesterId)
          .eq('requested_id', currentUser.id)
          .eq('status', 'pending')
          .limit(1)
          .maybeSingle();

      if (followRequest == null) {
        // Check if already accepted
        final existingFollow = await supabase
            .from('follows')
            .select('id')
            .eq('follower_id', requesterId)
            .eq('following_id', currentUser.id)
            .maybeSingle();

        if (existingFollow != null) {
          // Already accepted, remove the notification instead of updating it
          await _deleteNotification(notificationId);
          await _loadNotifications(); // Refresh the list
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Follow request was already accepted'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow request not found or already processed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final actualRequestId = followRequest['id'] as String;
      final requesterUsername =
          notification.data?['requester_username'] as String? ?? 'User';
      bool success = false;

      if (accept) {
        success =
            await _followRequestService.acceptFollowRequest(actualRequestId);
        if (success) {
          print(
              'DEBUG: Follow request accepted successfully, removing notification $notificationId');
          // Remove the notification after successful acceptance
          await _deleteNotification(notificationId);
          print('DEBUG: Notification removed, reloading notifications');
          // Reload notifications to reflect changes
          await _loadNotifications();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You are now friends with $requesterUsername!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('DEBUG: Failed to accept follow request');
        }
      } else {
        success =
            await _followRequestService.rejectFollowRequest(actualRequestId);
        if (success) {
          // Remove notification for rejected requests
          await _deleteNotification(notificationId);
          await _loadNotifications();
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'You are now friends with $requesterUsername!'
                : 'Follow request rejected'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
        _loadNotifications(); // Refresh notifications

        // Notify other parts of the app that follow status changed
        if (accept) {
          _notifyFollowStatusChanged();
        }
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

  Widget _buildNotificationItem(NotificationModel notification) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Do you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _deleteNotification(notification.id);
        if (mounted) {
          setState(() {
            _notifications.removeWhere((n) => n.id == notification.id);
          });
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.05),
        color: Colors.red,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: screenWidth * 0.06,
        ),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.01,
        ),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey[200]!
                : Colors.blue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          onTap: () => _markAsRead(notification),
          contentPadding: EdgeInsets.all(screenWidth * 0.03),
          leading: _buildNotificationAvatar(notification, screenWidth),
          title: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: screenWidth * 0.037,
                color: Colors.black87,
              ),
              children: _buildNotificationText(notification),
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.01),
            child: Text(
              _getTimeAgo(notification.createdAt),
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.grey[600],
              ),
            ),
          ),
          trailing: _buildNotificationTrailing(notification, screenWidth),
        ),
      ),
    );
  }

  Widget _buildNotificationAvatar(
      NotificationModel notification, double screenWidth) {
    final data = notification.data ?? {};
    final avatarUrl = data['requester_avatar'] ?? data['user_avatar'];
    final username = data['requester_username'] ?? data['username'] ?? 'User';

    return Stack(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.06,
          backgroundColor: const Color(0xFF007F8C),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        // Activity type icon
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.008),
            decoration: BoxDecoration(
              color: _getActivityColor(notification.type),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              _getActivityIcon(notification.type),
              size: screenWidth * 0.03,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildNotificationText(NotificationModel notification) {
    final data = notification.data ?? {};
    final username =
        data['requester_username'] ?? data['username'] ?? 'Someone';

    switch (notification.type) {
      case 'follow_request':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' wants to follow you'),
        ];
      case 'follow_accepted':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' accepted your follow request'),
        ];
      case 'follow_accepted_by_you':
        return [
          const TextSpan(text: 'Request Accepted - You are now friends with '),
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '!'),
        ];
      case 'post_like':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' liked your post'),
        ];
      case 'post_comment':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' commented on your post'),
        ];
      case 'campaign_like':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' liked your campaign'),
        ];
      case 'campaign_comment':
        return [
          TextSpan(
            text: username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' commented on your campaign'),
        ];
      default:
        return [TextSpan(text: notification.message)];
    }
  }

  Widget? _buildNotificationTrailing(
      NotificationModel notification, double screenWidth) {
    if (notification.type == 'follow_request') {
      return _buildFollowRequestActions(notification);
    } else if (notification.type == 'follow_accepted_by_you') {
      // Show a checkmark for accepted requests
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          color: Colors.white,
          size: screenWidth * 0.04,
        ),
      );
    } else if (!notification.isRead) {
      return Container(
        width: screenWidth * 0.025,
        height: screenWidth * 0.025,
        decoration: const BoxDecoration(
          color: Color(0xFF007F8C),
          shape: BoxShape.circle,
        ),
      );
    }
    return null;
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'follow_request':
      case 'follow_accepted':
        return Colors.blue;
      case 'post_like':
      case 'campaign_like':
        return Colors.red;
      case 'post_comment':
      case 'campaign_comment':
        return Colors.green;
      default:
        return const Color(0xFF007F8C);
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'follow_request':
      case 'follow_accepted':
        return Icons.person_add;
      case 'post_like':
      case 'campaign_like':
        return Icons.favorite;
      case 'post_comment':
      case 'campaign_comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildFollowRequestActions(NotificationModel notification) {
    final screenWidth = MediaQuery.of(context).size.width;
    final requestId = notification.data?['requester_id'] as String?;

    if (requestId == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.01,
      ),
      child: ElevatedButton(
        onPressed: () => _handleFollowRequest(notification.id, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          elevation: 0,
          minimumSize: Size(screenWidth * 0.2, screenWidth * 0.08),
        ),
        child: Text(
          'Accept',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _notifyFollowStatusChanged() {
    // This could be expanded to use a state management solution
    // For now, we'll rely on the didChangeDependencies in search page
    // to refresh when user returns to search
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF007F8C),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: screenWidth * 0.2,
                        color: Colors.grey,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'When you get notifications, they\'ll show up here',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
    );
  }
}
