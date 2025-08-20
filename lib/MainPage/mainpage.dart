import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:staymitra/Campaigns/campaigns_page.dart';
import 'package:staymitra/Home/home.dart';
import 'package:staymitra/Profile/profile.dart';
import 'package:staymitra/SearchUsers/user_search_page.dart';
import 'package:staymitra/Notifications/notifications_page.dart';
import 'package:staymitra/services/notification_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;

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

    return WillPopScope(
      onWillPop: _onWillPop,
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
                    _loadUnreadNotificationCount(); // Refresh count after returning
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

        floatingActionButton: (_currentIndex == 0 || _currentIndex == 3)
            ? FloatingActionButton(
                heroTag: "main_fab",
                onPressed: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.media,
                    );
                    if (result != null) {
                      final selectedPaths =
                          result.paths.whereType<String>().toList();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Selected ${selectedPaths.length} files")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No file selected")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                backgroundColor: const Color.fromARGB(255, 21, 7, 92),
                shape: const CircleBorder(),
                child: Icon(Icons.add,
                    size: screenWidth * 0.07, color: Colors.white),
              )
            : null,

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF017E8D),
          unselectedItemColor: Colors.grey[600],
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined), label: "Account"),
          ],
        ),
      ),
    );
  }
}
