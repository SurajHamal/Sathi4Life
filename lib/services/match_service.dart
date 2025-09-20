import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Max daily swipes limit
  static const int maxDailySwipes = 20;

  Future<void> likeUser(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userLikesRef = _firestore.collection('users').doc(user.uid).collection('likes').doc(targetUid);
    await userLikesRef.set({'likedAt': FieldValue.serverTimestamp()});

    final targetLikesRef = _firestore.collection('users').doc(targetUid).collection('likes').doc(user.uid);
    final targetLiked = await targetLikesRef.get();

    if (targetLiked.exists) {
      await _createMatch(user.uid, targetUid);
    }
  }

  Future<void> passUser(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('passes').doc(targetUid).set({
      'passedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> undoLike(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userLikesRef = _firestore.collection('users').doc(user.uid).collection('likes').doc(targetUid);
    await userLikesRef.delete();
  }

  Future<void> undoPass(String targetUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userPassesRef = _firestore.collection('users').doc(user.uid).collection('passes').doc(targetUid);
    await userPassesRef.delete();
  }

  Future<void> _createMatch(String uid1, String uid2) async {
    final matchId = uid1.compareTo(uid2) < 0 ? '$uid1\_$uid2' : '$uid2\_$uid1';

    await _firestore.collection('matches').doc(matchId).set({
      'users': [uid1, uid2],
      'matchedAt': FieldValue.serverTimestamp(),
      'chatId': matchId,
    });
  }

  Future<List<Map<String, dynamic>>> getMatchedUsers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('matches')
        .where('users', arrayContains: user.uid)
        .get();

    List<Map<String, dynamic>> matches = [];

    for (var doc in snapshot.docs) {
      List<dynamic> userIds = doc['users'];
      String otherUid = userIds.firstWhere((uid) => uid != user.uid);
      final userDoc = await _firestore.collection('users').doc(otherUid).get();
      if (userDoc.exists) matches.add(userDoc.data()!);
    }

    return matches;
  }

  double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
                sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  Future<List<Map<String, dynamic>>> getSuggestedUsers({String? countryFilter}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final currentUserId = user.uid;

    final allProfilesSnapshot = await _firestore.collection('profiles').get();
    final likedDocs = await _firestore.collection('users').doc(currentUserId).collection('likes').get();
    final passedDocs = await _firestore.collection('users').doc(currentUserId).collection('passes').get();

    final likedIds = likedDocs.docs.map((d) => d.id).toSet();
    final passedIds = passedDocs.docs.map((d) => d.id).toSet();

    List<Map<String, dynamic>> suggestions = [];

    for (var doc in allProfilesSnapshot.docs) {
      if (doc.id == currentUserId || likedIds.contains(doc.id) || passedIds.contains(doc.id)) continue;

      final data = doc.data() as Map<String, dynamic>;
      final userCountry = data['country'] as String? ?? '';

      // If countryFilter is set, only include users from that country
      if (countryFilter != null && countryFilter.isNotEmpty && userCountry != countryFilter) {
        continue;
      }

      data['uid'] = doc.id;
      suggestions.add(data);
    }

    // Optional: Sort alphabetically by user name for consistent ordering
    suggestions.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    return suggestions;
  }


  Future<bool> canSwipeToday() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final swipeCountDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('swipeCounts')
        .doc(_getTodayDateString())
        .get();

    if (!swipeCountDoc.exists) return true;

    final count = swipeCountDoc.data()?['count'] ?? 0;
    return count < maxDailySwipes;
  }

  Future<void> superLikeUser(String uid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('super_likes')
        .doc(uid)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> undoSuperLike(String uid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('super_likes')
        .doc(uid)
        .delete();
  }

  Future<void> incrementSwipeCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final swipeCountRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('swipeCounts')
        .doc(_getTodayDateString());

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(swipeCountRef);
      if (!snapshot.exists) {
        transaction.set(swipeCountRef, {'count': 1});
      } else {
        final currentCount = snapshot.data()?['count'] ?? 0;
        transaction.update(swipeCountRef, {'count': currentCount + 1});
      }
    });
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }
}
