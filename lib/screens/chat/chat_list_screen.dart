import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Center(child: Text('No active chats'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              final chatPartnerId = participants.firstWhere((id) => id != currentUser.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('profiles').doc(chatPartnerId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(title: Text('Loading...'));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final partnerName = userData['name'] ?? 'User';
                  final profileImageUrl = userData['imageUrl'];
                  final isOnline = userData['isOnline'] == true;

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null ? Icon(Icons.person) : null,
                        ),
                        if (isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(partnerName),
                    subtitle: Text(chat['lastMessage'] ?? ''),
                    trailing: chat['lastUpdated'] != null
                        ? Text(
                      _formatTimestamp(chat['lastUpdated']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chat.id,
                            otherUserName: partnerName,
                            otherUserId: chatPartnerId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();

    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
