import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? peerAvatar; // optional: asset or network path

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    this.peerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctr = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  // Editing / Reply state
  String? _editingId;
  _Message? _replyingTo;

  final List<_Message> _messages = [
    _Message(id: 'm1', text: "Hey! Press the Grey Message, you know you want to", isMe: true,  time: DateTime.now().subtract(const Duration(minutes: 9)), isRead: true),
    _Message(id: 'm2', text: "Press here!! It only gets better from here, you know you want to", isMe: false, time: DateTime.now().subtract(const Duration(minutes: 8))),
    _Message(id: 'm3', text: "The quick brown fox jumped over the lazy dog.", isMe: true,  time: DateTime.now().subtract(const Duration(minutes: 6)), isRead: true),
    _Message(id: 'm4', text: "Bonjour! you can press me too! Go ahead press me 😄", isMe: false, time: DateTime.now().subtract(const Duration(minutes: 5))),
  ];

  @override
  void dispose() {
    _ctr.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // === Actions ===

  void _send() {
    final text = _ctr.text.trim();
    if (text.isEmpty) return;

    if (_editingId != null) {
      // Save edit
      final i = _messages.indexWhere((m) => m.id == _editingId);
      if (i != -1) {
        setState(() => _messages[i] = _messages[i].copyWith(text: text));
      }
      _editingId = null;
      _ctr.clear();
      _replyingTo = null;
      return;
    }

    // Normal send (with optional replyTo)
    final msg = _Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      time: DateTime.now(),
      isRead: false,
      replyToId: _replyingTo?.id,
    );

    setState(() => _messages.add(msg));
    _ctr.clear();
    _replyingTo = null;

    // Scroll down
    Future.delayed(const Duration(milliseconds: 60), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onLongPress(_Message message) async {
    final isMine = message.isMe;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            _actionTile(
              icon: Icons.edit_rounded,
              label: 'Edit',
              enabled: isMine,
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            _actionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              enabled: isMine,
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            _actionTile(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );

    switch (action) {
      case 'reply':
        setState(() => _replyingTo = message);
        FocusScope.of(context).requestFocus(_focus);
        break;
      case 'edit':
        if (!isMine) return;
        setState(() {
          _editingId = message.id;
          _replyingTo = null;
        });
        _ctr
          ..text = message.text
          ..selection = TextSelection(baseOffset: 0, extentOffset: _ctr.text.length);
        FocusScope.of(context).requestFocus(_focus);
        break;
      case 'delete':
        if (!isMine) return;
        setState(() => _messages.removeWhere((m) => m.id == message.id));
        break;
      case 'copy':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied')),
        );
        break;
      default:
        break;
    }
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final color = enabled ? Theme.of(context).colorScheme.onSurface : Colors.grey;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: enabled ? onTap : null,
    );
  }

  _Message? _byId(String? id) {
    if (id == null) return null;
    return _messages.cast<_Message?>().firstWhere((m) => m?.id == id, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0F10) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: _ChatAppBar(
        peerId: widget.peerId,
        peerName: widget.peerName,
        peerAvatar: widget.peerAvatar,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final prev = i - 1 >= 0 ? _messages[i - 1] : null;
                final isNewGroup = prev == null || prev.isMe != msg.isMe;

                return GestureDetector(
                  onLongPress: () => _onLongPress(msg),
                  child: _MessageRow(
                    message: msg,
                    showAvatar: !msg.isMe && isNewGroup,
                    replyTo: _byId(msg.replyToId),
                    peerName: widget.peerName,
                  ),
                );
              },
            ),
          ),

          // Reply / Edit banner
          if (_replyingTo != null || _editingId != null)
            SafeArea(
              bottom: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1D1E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF2A2D2F) : const Color(0xFFE7E7E7)),
                ),
                child: Row(
                  children: [
                    Container(width: 3, height: 28, decoration: const BoxDecoration(color: Color(0xFF00B3C6), borderRadius: BorderRadius.all(Radius.circular(2)))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId != null
                                ? 'Editing message'
                                : 'Replying to ${_replyingTo!.isMe ? "You" : widget.peerName}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          if (_replyingTo != null)
                            Text(
                              _snippet(_replyingTo!.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      splashRadius: 18,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() { _replyingTo = null; _editingId = null; }),
                    ),
                  ],
                ),
              ),
            ),

          // Input row
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1D1E) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A2D2F) : const Color(0xFFE7E7E7),
                        ),
                      ),
                      child: TextField(
                        controller: _ctr,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: "Message",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF00B3C6), Color(0xFF007F8C)]),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _snippet(String t) => t.length <= 60 ? t : '${t.substring(0, 60)}…';
}

// --- AppBar ---

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String peerId;
  final String peerName;
  final String? peerAvatar;
  const _ChatAppBar({
    required this.peerId,
    required this.peerName,
    this.peerAvatar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    String initials(String s) {
      final parts = s.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) return parts.first[0].toUpperCase();
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }

    Widget avatar() {
      if (peerAvatar != null && peerAvatar!.isNotEmpty) {
        if (peerAvatar!.startsWith('http')) {
          return CircleAvatar(radius: 20, backgroundImage: NetworkImage(peerAvatar!));
        } else {
          return CircleAvatar(radius: 20, backgroundImage: AssetImage(peerAvatar!));
        }
      }
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF007F8C),
        child: Text(initials(peerName),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? const Color(0xFF222426) : const Color(0xFFECECEC);

    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: divider, width: 1)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: Theme.of(context).colorScheme.onSurface,
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Hero(tag: 'chat_avatar_$peerId', child: avatar()),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              const SizedBox(height: 2),
              const Text("online",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        const SizedBox(width: 4),
      ],
    );
  }
}

// --- Message row / bubble ---

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.showAvatar,
    required this.replyTo,
    required this.peerName,
  });

  final _Message message;
  final bool showAvatar;
  final _Message? replyTo;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final align = message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return Padding(
      padding: EdgeInsets.only(
        top: showAvatar ? 10 : 4,
        bottom: 4,
        left: message.isMe ? 48 : 8,
        right: message.isMe ? 8 : 48,
      ),
      child: Row(
        mainAxisAlignment: align,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            AnimatedOpacity(
              opacity: showAvatar ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2D5948),
                child: Text(
                  (peerName.isNotEmpty ? peerName[0] : 'A').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: _Bubble(message: message, replyTo: replyTo, peerName: peerName)),
          if (message.isMe) const SizedBox(width: 6),
          if (message.isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Icon(
                message.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                size: 16,
                color: message.isRead ? const Color(0xFF00B3C6) : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.replyTo, required this.peerName});
  final _Message message;
  final _Message? replyTo;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: message.isMe ? const Radius.circular(18) : const Radius.circular(6),
      bottomRight: message.isMe ? const Radius.circular(6) : const Radius.circular(18),
    );

    final surface = isDark ? const Color(0xFF1B1D1E) : Colors.white;
    final surfaceBorder = isDark ? const Color(0xFF2A2D2F) : const Color(0xFFE7E7E7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: message.isMe ? const LinearGradient(colors: [Color(0xFF00B3C6), Color(0xFF007F8C)]) : null,
        color: message.isMe ? null : surface,
        borderRadius: radius,
        border: message.isMe ? null : Border.all(color: surfaceBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (replyTo != null) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: message.isMe ? Colors.white.withOpacity(0.15) : (isDark ? const Color(0xFF121315) : const Color(0xFFF6F7F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: message.isMe ? Colors.white70 : const Color(0xFF00B3C6), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyTo!.isMe ? 'You' : peerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: message.isMe ? Colors.white : (isDark ? Colors.white.withOpacity(.9) : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyTo!.text.length <= 90 ? replyTo!.text : '${replyTo!.text.substring(0, 90)}…',
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isMe ? Colors.white.withOpacity(.9) : Colors.grey.shade700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            message.text,
            style: TextStyle(
              color: message.isMe ? Colors.white : (isDark ? Colors.white.withOpacity(.9) : Colors.black87),
              fontSize: 15.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmtTime(message.time),
            style: TextStyle(
              fontSize: 11,
              color: message.isMe ? Colors.white.withOpacity(.85) : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final am = t.hour < 12 ? 'AM' : 'PM';
    return "$h:$m $am";
  }
}

// --- Model ---

class _Message {
  final String id;
  final bool isMe;
  final DateTime time;
  final bool isRead;
  final String? replyToId;
  final String text;

  _Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
    this.replyToId,
  });

  _Message copyWith({String? text}) => _Message(
        id: id,
        text: text ?? this.text,
        isMe: isMe,
        time: time,
        isRead: isRead,
        replyToId: replyToId,
      );
}
