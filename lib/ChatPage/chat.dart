import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
     double iconSize = screenWidth * 0.06;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: InkWell(
  onTap: () => Navigator.pop(context),
  child: CircleAvatar(
    radius: screenWidth * 0.05,
    backgroundColor: Colors.white,
    child: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
  ),
),
        title: Center(
          child: CircleAvatar(
            backgroundImage: AssetImage('assets/usery_avatar.png'), // UserY profile image
            radius: 30,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ChatBubble(message: 'Hey! Press the Grey Message. you know you want to', isSender: true),
                ChatBubble(message: 'Press here!! It only gets better from here know you want to', isSender: false),
                ChatBubble(message: 'The quick brown fox jumped over the lazy dog.', isSender: true),
                ChatBubble(message: 'Bonjour! you can press me too! Go ahead press me 😄', isSender: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      // Handle message sending logic here
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF007F8C)),
                  onPressed: () {
                    // Handle sending message
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;

  const ChatBubble({required this.message, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSender ? Color(0xFF007F8C) : Color(0xFFE6E6E6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isSender ? Radius.circular(15) : Radius.circular(0),
            bottomRight: isSender ? Radius.circular(0) : Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isSender ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}