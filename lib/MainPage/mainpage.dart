import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:staymitra/Campaigns/campaigns_page.dart';
import 'package:staymitra/Home/home.dart';
import 'package:staymitra/Profile/profile.dart';
import 'package:staymitra/SearchUsers/user_search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    StaymithraHomePage(),
    const CampaignsPage(),
    const UserSearchPage(),
    const ProfilePage(),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0); // go back to Home tab
      return false; // don’t pop the route
    }
    return true; // allow app to close
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Use IndexedStack so tab state is preserved
        body: IndexedStack(index: _currentIndex, children: _pages),

        floatingActionButton: (_currentIndex == 0 || _currentIndex == 3)
            ? FloatingActionButton(
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
