import 'package:cloud_firestore/cloud_firestore.dart';

class UserCardProfile {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String profileImageUrl;
  final String? bio;

  UserCardProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.profileImageUrl,
    this.bio,
  });

  factory UserCardProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCardProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      bio: data['bio'],
    );
  }

  factory UserCardProfile.fromMap(Map<String, dynamic> data) {
    return UserCardProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      bio: data['bio'],
    );
  }
}
