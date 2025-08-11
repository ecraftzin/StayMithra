import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:staymitra/Home/home.dart';
import 'package:staymitra/Camping/camping.dart';
import 'package:staymitra/SearchUsers/search.dart';
import 'package:staymitra/Profile/profile.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    StaymithraHomePage(),
    UploadPage(),
    ChatSearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;


    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 3)
          ? FloatingActionButton(
           onPressed: () async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media, // Picks both image and video
    );

    if (result != null) {
      List<String> selectedPaths = result.paths.whereType<String>().toList();
      print("Selected files: $selectedPaths");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected ${selectedPaths.length} files")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
    }
  } catch (e) {
    print("File picking error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
},


              backgroundColor: const Color.fromARGB(255, 21, 7, 92),
              shape: const CircleBorder(),
              child: Icon(Icons.add, size: screenWidth * 0.07, color: Colors.white),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF017E8D),
        unselectedItemColor: Colors.grey[600],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: "Account"),
        ],
      ),
    );
  }
}
