import 'package:flutter/material.dart';

class StaymithraBottomNavBar extends StatefulWidget {
  const StaymithraBottomNavBar({super.key});

  @override
  _StaymithraBottomNavBarState createState() =>
      _StaymithraBottomNavBarState();
}

class _StaymithraBottomNavBarState extends State<StaymithraBottomNavBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600; // Detect if the screen width is greater than 600px

    // If the screen is wide (tablet or landscape), use a row layout
    return isWideScreen
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.confirmation_num_outlined, "Booking", 1),
              _buildNavItem(Icons.search, "Search", 2),
              _buildNavItem(Icons.account_circle_outlined, "Account", 3),
            ],
          )
        : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFF5F5F5),
            selectedItemColor: const Color(0xFF017E8D),
            unselectedItemColor: Colors.grey[600],
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_num_outlined),
                label: "Booking",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: "Search",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                label: "Account",
              ),
            ],
          );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });

        switch (index){
          case 0:
          Navigator.pushReplacementNamed(context, '/StaymithraHomePage');
          break;
          case 1:
          Navigator.pushReplacementNamed(context, '/UploadPage');
          break;
          case 2:
          Navigator.pushReplacementNamed(context, '/ChatSearchPage');
          case 3:
          Navigator.pushReplacementNamed(context, '/ProfilePage');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _currentIndex == index
                ? const Color(0xFF017E8D)
                : Colors.grey[600],
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _currentIndex == index
                  ? const Color(0xFF017E8D)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
