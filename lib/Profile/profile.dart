import 'package:flutter/material.dart';
import 'package:staymitra/Profile/profileedit.dart';
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
//                      InkWell(
//   onTap: () => Navigator.pop(context),
//   child: CircleAvatar(
//     radius: screenWidth * 0.05,
//     backgroundColor: Colors.white,
//     child: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
//   ),
// ),

                      // Text(
                      //   "Profile",
                      //   style: TextStyle(
                      //     fontSize: screenWidth * 0.05,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.white,
                      //   ),
                      // ),
                      IconButton(onPressed: (){
                     Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfilePage()));
                      }, 
                      icon: Icon(Icons.edit, color: Colors.white,))
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                CircleAvatar(
                  radius: screenWidth * 0.18, // responsive avatar size
                  backgroundImage: const AssetImage('assets/images/marvel.png'),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  "Paul",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF015F6B),
                  ),
                ),
                Text(
                  "mail id @gmail.com",
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF015F6B),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                      children: const [
                        ProfileStat(title: "Following", count: "0"),
                        VerticalDivider(thickness: 1, color: Colors.grey),
                        ProfileStat(title: "Posts", count: "0"),
                        VerticalDivider(thickness: 1, color: Colors.grey),
                        ProfileStat(title: "Followers", count: "0"),
                      ],
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

  const ProfileStat({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: screenWidth * 0.04),
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
