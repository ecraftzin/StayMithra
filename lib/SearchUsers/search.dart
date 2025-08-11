import 'package:flutter/material.dart';
import 'package:staymitra/ChatPage/chat.dart';
// Make sure to import the ChatPage

class ChatSearchPage extends StatelessWidget {
  final List<Map<String, String>> chatList = [
    {'name': 'Sajib Rahman', 'message': 'Hi, John! How are you doing?'},
    {'name': 'Adom Shafi', 'message': 'Hi, John! How are you doing?'},
    {'name': 'HR Rumen', 'message': 'Hi, John! How are you doing?'},
    {'name': 'Anjelina', 'message': 'Hi, John! How are you doing?'},
    {'name': 'Alexa Shorna', 'message': 'Hi, John! How are you doing?'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenWidth * 0.04),

              // Search Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'search',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenWidth * 0.05),

              // Chat List
              Expanded(
                child: ListView.builder(
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to ChatPage on tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              // name: chat['name']!,
                              // message: chat['message']!,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.035),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  AssetImage('assets/images/user.jpg'),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  chat['message']!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
