import 'package:flutter/material.dart';
class EditProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjusting padding and margins to be responsive
    double horizontalPadding = screenWidth * 0.05;
    double verticalPadding = screenHeight * 0.02;
    double avatarSize = screenWidth * 0.18;
    double textFieldHeight = screenHeight * 0.06;
    double iconSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient container
          Container(
            height: screenHeight * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF007F99), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
//                        InkWell(
//   onTap: () => Navigator.pop(context),
//   child: CircleAvatar(
//     radius: screenWidth * 0.05,
//     backgroundColor: Colors.white,
//     child: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
//   ),
// ),

                        // Edit profile text
                        // Text(
                        //   "Edit profile",
                        //   style: TextStyle(
                        //     fontSize: screenWidth * 0.05,
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.white,
                        //   ),
                        // ),
                        // Check icon (for saving changes)
                        Icon(Icons.check, color: Colors.white, size: iconSize),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  // Profile photo
                  CircleAvatar(
                    radius: avatarSize,
                    backgroundImage: const AssetImage('assets/images/marvel.png')
                  ),
                  SizedBox(height: verticalPadding),
                  // Change profile photo text
                  Text(
                    "Change profile photo",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: const Color(0xFF007F99),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  // Input fields
                  _buildTextField("Username", screenWidth, textFieldHeight),
                  _buildDivider(),
                  _buildTextField("Email", screenWidth, textFieldHeight),
                  _buildDivider(),
                  _buildTextField("Phonenumber", screenWidth, textFieldHeight),
                  _buildDivider(),
                  _buildTextField("Place", screenWidth, textFieldHeight),
                  _buildDivider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to create the text fields
  Widget _buildTextField(String hintText, double screenWidth, double textFieldHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: textFieldHeight * 0.35), // Adjust vertical padding
        ),
      ),
    );
  }

  // Divider widget
  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.grey);
  }
}
