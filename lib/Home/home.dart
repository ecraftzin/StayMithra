import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:staymitra/Camping/camping.dart';
import 'package:staymitra/SearchUsers/search.dart';


class StaymithraHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'staymithra',
          style: TextStyle(
            color: Color(0xFF007F8C),
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(onPressed:(){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>UploadPage()));
          },
           icon:Icon(FontAwesomeIcons.squarePlus, color: Colors.black, size: screenWidth * 0.06)),
          SizedBox(width: screenWidth * 0.025),
          IconButton(onPressed: (){},
          icon: Icon(FontAwesomeIcons.heart, color: Colors.black, size: screenWidth * 0.06)),
          SizedBox(width: screenWidth * 0.025),
          IconButton(onPressed: (){
           Navigator.push(context, MaterialPageRoute(builder:(context)=>ChatSearchPage()));
          }, 
          icon:Icon(FontAwesomeIcons.facebookMessenger, color: Colors.black, size: screenWidth * 0.06)),
          SizedBox(width: screenWidth * 0.025),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(screenWidth * 0.025),
        children: [
          PostCardWidget(screenWidth: screenWidth),
        ],
      ),
    );
  }
}

class PostCardWidget extends StatelessWidget {
  final double screenWidth;

  const PostCardWidget({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: screenWidth * 0.025,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: const AssetImage('assets/images/marvel.png'),
                  radius: screenWidth * 0.055,
                ),
                SizedBox(width: screenWidth * 0.025),
                Expanded(
                  child: Text(
                    "marvel",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  // Add edit functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Post'),
                onTap: () {
                  Navigator.pop(context);
                  // Add delete functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Add share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  },
  child: Icon(Icons.more_vert, size: screenWidth * 0.06),
),
              ],
            ),
          ),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: Image.network(
              'https://m.media-amazon.com/images/I/81e1IWtwFQL._UF1000,1000_QL80_.jpg',
              width: double.infinity,
              height: screenWidth * 1.1,
              fit: BoxFit.cover,
            ),
          ),

          // Description
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Joined by ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      TextSpan(
                        text: "@thekarmaan ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      TextSpan(
                        text: "and 5 others",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  "Available Slots: 10",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  "Scheduled on: 16.08.2025",
                  style: TextStyle(
                    color: const Color(0xFF007F8C),
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Time: 5:00 PM",
                  style: TextStyle(
                    color: const Color(0xFF007F8C),
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                // Share & Book Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(FontAwesomeIcons.paperPlane, size: screenWidth * 0.05),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(FontAwesomeIcons.bagShopping, size: screenWidth * 0.05),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
