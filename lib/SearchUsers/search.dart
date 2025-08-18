import 'package:flutter/material.dart';
import 'package:staymitra/ChatPage/real_chat_screen.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchCtr = TextEditingController();

  final List<Map<String, String>> chatList = const [
    {'name': 'Sajib Rahman', 'message': 'Hi, John! How are you doing?'},
    {'name': 'Adom Shafi', 'message': 'Ping me when free.'},
    {'name': 'HR Rumen', 'message': 'Please check the doc.'},
    {'name': 'Muhammed Farhan', 'message': 'Travel plan update.'},
    {'name': 'Farhan Mustafa', 'message': 'Let’s meet tomorrow.'},
    {'name': 'Farhan KP', 'message': 'Files shared.'},
    {'name': 'Anjelina', 'message': 'Good morning!'},
    {'name': 'Alexa Shorna', 'message': 'Lunch?'},
  ];

  String get _q => _searchCtr.text.trim().toLowerCase();

  List<Map<String, String>> get _filtered {
    if (_q.isEmpty) return chatList;
    return chatList.where((c) {
      final name = (c['name'] ?? '').toLowerCase();
      return name.contains(_q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

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
                  // GestureDetector(
                  //   onTap: () => Navigator.pop(context),
                  //   child: const Icon(Icons.arrow_back_ios, size: 20),
                  // ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtr,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_q.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtr.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenWidth * 0.05),

              // List / Empty
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matches for “${_searchCtr.text.trim()}”.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: screenWidth * 0.035),
                        itemBuilder: (context, index) {
                          final chat = _filtered[index];
                          final name = chat['name'] ?? '';
                          final message = chat['message'] ?? '';
                          final id = _stableId(name);
                          final heroTag = 'chat_avatar_$id';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RealChatScreen(
                                    peerId: id,
                                    peerName: name,
                                    // peerAvatar: 'assets/avatars/$id.png', // if you have one
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Hero(
                                  tag: heroTag,
                                  child: _initialsAvatar(name),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _highlightedName(name, _q),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  // --- Helpers ---

  String _stableId(String name) => 'u_${name.hashCode & 0x7fffffff}';

  Widget _highlightedName(String name, String queryLower) {
    if (queryLower.isEmpty) {
      return Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );
    }
    final lower = name.toLowerCase();
    final start = lower.indexOf(queryLower);
    if (start < 0) {
      return Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );
    }
    final end = start + queryLower.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: name.substring(0, start)),
          TextSpan(
            text: name.substring(start, end),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          TextSpan(text: name.substring(end)),
        ],
      ),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _initialsAvatar(String name) => CircleAvatar(
        radius: 28,
        backgroundColor: _colorFrom(name),
        child: Text(
          _initials(name),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  Color _colorFrom(String seed) {
    final hash = seed.hashCode & 0x7fffffff;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.50, 0.55).toColor();
  }
}
