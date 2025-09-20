import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates a unique and consistent chat ID for any pair of users.
String generateChatId(String userId1, String userId2) {
  final sorted = [userId1, userId2]..sort(); // ensures same order every time
  return sorted.join('_');
}

/// Creates the chat if it does not exist, otherwise returns silently.
/// Since chatId is deterministic, callers already know the chatId.
Future<void> createOrGetChat(String userId1, String userId2) async {
  final chatId = generateChatId(userId1, userId2);
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  final docSnapshot = await chatRef.get();

  if (!docSnapshot.exists) {
    await chatRef.set({
      'participants': [userId1, userId2],
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'typingStatus': {
        userId1: false,
        userId2: false,
      },
      'readStatus': {
        userId1: true,
        userId2: false,
      },
    });
  }
}
