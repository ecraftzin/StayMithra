import 'package:flutter/material.dart';
import 'package:staymitra/Campaigns/campaigns_page.dart';
import 'package:staymitra/Home/home.dart';
import 'package:staymitra/Profile/profile.dart';
import 'package:staymitra/SearchUsers/user_search_page.dart';
import 'package:staymitra/Notifications/notifications_page.dart';
import 'package:staymitra/services/notification_service.dart';
import 'package:staymitra/services/chat_service.dart';
import 'package:staymitra/services/auth_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  int _unreadNotificationCount = 0;
  int _unreadChatCount = 0;

  final List<Widget> _pages = [
    const StaymithraHomePage(),
    const CampaignsPage(),
    const UserSearchPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
    _loadUnreadChatCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    } catch (e) {
      // Handle error silently
    }
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

  Future<void> _refreshAllCounts() async {
    await _loadUnreadNotificationCount();
    await _loadUnreadChatCount();
  }

  Future<void> _navigateToCreatePost() async {
    // Navigate to create post page
    final result = await Navigator.pushNamed(context, '/create-post');
    if (result == true) {
      // Refresh home page if post was created
      // The home page will automatically refresh when we return
    }
  }

  Future<void> _navigateToCreateCampaign() async {
    // Navigate to create campaign page
    final result = await Navigator.pushNamed(context, '/create-campaign');
    if (result == true) {
      // Refresh explore page and profile if campaign was created
      // The explore page will automatically refresh when we return
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0); // go back to Home tab
      return false; // don’t pop the route
    }
    return true; // allow app to close
  }

  String _getPageTitle() {
    switch (_currentIndex) {
      case 0:
        return 'StayMithra';
      case 1:
        return 'Campaigns';
      case 2:
        return 'Search';
      case 3:
        return 'Profile';
      default:
        return 'StayMithra';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0); // go back to Home tab
        } else {
          // Exit app instead of popping
          if (mounted) {
            // Use system navigator to exit app
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _getPageTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF007F8C),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Stack(
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                    _refreshAllCounts(); // Refresh all counts after returning
                  },
                  icon: const Icon(Icons.notifications, color: Colors.white),
                ),
                if (_unreadNotificationCount > 0)
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
                        _unreadNotificationCount > 99
                            ? '99+'
                            : '$_unreadNotificationCount',
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
          ],
        ),
        // Use IndexedStack so tab state is preserved
        body: IndexedStack(index: _currentIndex, children: _pages),

        floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
            ? FloatingActionButton(
                heroTag: "main_fab",
                onPressed: () async {
                  if (_currentIndex == 0) {
                    // Home page - Create Post
                    await _navigateToCreatePost();
                  } else if (_currentIndex == 1) {
                    // Explore page - Create Campaign
                    await _navigateToCreateCampaign();
                  }
                },
                backgroundColor: const Color.fromARGB(255, 21, 7, 92),
                shape: const CircleBorder(),
                child: Icon(
                    _currentIndex == 0 ? Icons.post_add : Icons.campaign,
                    size: screenWidth * 0.07,
                    color: Colors.white),
              )
            : null,

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF017E8D),
          unselectedItemColor: Colors.grey[600],
          onTap: (index) async {
            setState(() => _currentIndex = index);
            // Refresh chat count when navigating to search/chat tab
            if (index == 2) {
              await _loadUnreadChatCount();
            }
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: "Home"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.search),
                  if (_unreadChatCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
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
              label: "Search",
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined), label: "Account"),
          ],
        ),
      ),
    );
  }
}
