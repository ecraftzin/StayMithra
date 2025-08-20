import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/follow_request_service.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final FollowRequestService _followRequestService = FollowRequestService();
  
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _handleFollowRequest(String requestId, bool accept) async {
    bool success;
    if (accept) {
      success = await _followRequestService.acceptFollowRequest(requestId);
    } else {
      success = await _followRequestService.rejectFollowRequest(requestId);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Follow request accepted' : 'Follow request rejected'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
      _loadNotifications(); // Refresh notifications
    }
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      elevation: notification.isRead ? 1 : 3,
      child: ListTile(
        onTap: () => _markAsRead(notification),
        leading: CircleAvatar(
          backgroundColor: Color(int.parse('0xFF${notification.colorHex.substring(1)}')),
          child: Icon(
            _getIconData(notification.iconName),
            color: Colors.white,
            size: screenWidth * 0.05,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: notification.type == 'follow_request' 
            ? _buildFollowRequestActions(notification)
            : notification.isRead 
                ? null 
                : Container(
                    width: screenWidth * 0.03,
                    height: screenWidth * 0.03,
                    decoration: const BoxDecoration(
                      color: Color(0xFF007F8C),
                      shape: BoxShape.circle,
                    ),
                  ),
      ),
    );
  }

  Widget _buildFollowRequestActions(NotificationModel notification) {
    final screenWidth = MediaQuery.of(context).size.width;
    final requestId = notification.data?['requester_id'] as String?;
    
    if (requestId == null) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _handleFollowRequest(notification.id, true),
          icon: Icon(
            Icons.check_circle,
            color: Colors.green,
            size: screenWidth * 0.06,
          ),
        ),
        IconButton(
          onPressed: () => _handleFollowRequest(notification.id, false),
          icon: Icon(
            Icons.cancel,
            color: Colors.red,
            size: screenWidth * 0.06,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'person_add_alt_1':
        return Icons.person_add_alt_1;
      case 'favorite':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      default:
        return Icons.notifications;
    }
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
