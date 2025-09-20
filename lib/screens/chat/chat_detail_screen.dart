import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  bool _isOtherOnline = false;

  @override
  void initState() {
    super.initState();
    _listenTypingStatus();
    _listenOnlineStatus();
  }

  void _listenTypingStatus() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((docSnapshot) {
      if (!docSnapshot.exists) return;
      final typingStatus = docSnapshot.data()?['typingStatus'] as Map<String, dynamic>? ?? {};

      final otherUserId = widget.otherUserId;
      final otherTyping = typingStatus[otherUserId] ?? false;
      setState(() {
        _otherUserTyping = otherTyping;
      });
    });
  }

  void _listenOnlineStatus() {
    FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          _isOtherOnline = data?['isOnline'] ?? false;
        });
      }
    });
  }

  void _updateTypingStatus(bool isTyping) {
    if (currentUser == null) return;
    _isTyping = isTyping;
    final typingUpdate = {currentUser!.uid: isTyping};

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'typingStatus': typingUpdate,
    }, SetOptions(merge: true));
  }

  void _onTypingChanged(String text) {
    if (!_isTyping) {
      _updateTypingStatus(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || currentUser == null) return;

    final messageData = {
      'senderId': currentUser!.uid,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUser!.uid],
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    await chatRef.collection('messages').add(messageData);

    await chatRef.set({
      'lastMessage': messageText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'typingStatus': {currentUser!.uid: false},
    }, SetOptions(merge: true));

    _messageController.clear();
    _updateTypingStatus(false);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatMessagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (_otherUserTyping)
              const Text('Typing...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            if (!_otherUserTyping)
              Text(
                _isOtherOnline ? 'Online' : 'Offline',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatMessagesStream.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                // Mark messages as read
                Future.microtask(() {
                  for (var msg in messages) {
                    final readBy = List<String>.from(msg['readBy'] ?? []);
                    if (!readBy.contains(currentUser!.uid) && msg['senderId'] != currentUser!.uid) {
                      FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .doc(msg.id)
                          .update({
                        'readBy': FieldValue.arrayUnion([currentUser!.uid]),
                      });
                    }
                  }
                });

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser?.uid;
                    final readBy = List<String>.from(msg['readBy'] ?? []);
                    final isRead = readBy.length > 1;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.red[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(msg['text']),
                            if (isMe && isRead)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('✓ Seen', style: TextStyle(fontSize: 10, color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onChanged: _onTypingChanged,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.red,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
