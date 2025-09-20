import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print("Failed to fetch user profile: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    final uid = profileData['uid'];
    if (uid == null) throw Exception('User ID is missing');
    await _firestore.collection('users').doc(uid).set(profileData, SetOptions(merge: true));
  }

  /// Upload a photo with unique name (timestamp) and return URL
  Future<String?> uploadPhoto({File? imageFile, Uint8List? imageBytes}) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("🚫 No user logged in.");
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('profile_photos/${user.uid}/$timestamp.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        if (imageBytes == null) {
          print("❌ No image bytes provided for web upload");
          return null;
        }
        uploadTask = ref.putData(imageBytes);
      } else {
        if (imageFile == null) {
          print("❌ No image file provided for mobile upload");
          return null;
        }
        uploadTask = ref.putFile(imageFile);
      }

      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        final imageUrl = await ref.getDownloadURL();
        print("✅ Image uploaded. URL: $imageUrl");
        return imageUrl;
      } else {
        print("❌ Upload failed. Status: ${snapshot.state}");
        return null;
      }
    } catch (e) {
      print("❌ Exception during upload: $e");
      return null;
    }
  }

  /// Update user photos list and profile image URL atomically
  Future<void> updateUserPhotos({
    required List<String> photoUrls,
    required String profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged in user');

    await _firestore.collection('users').doc(user.uid).set({
      'photoUrls': photoUrls,
      'profileImageUrl': profileImageUrl,
      'uid': user.uid,
    }, SetOptions(merge: true));
  }
}
