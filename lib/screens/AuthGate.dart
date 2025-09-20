import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'welcome_screen.dart';
import 'profile_setup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  Future<Widget> _handleAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return WelcomeScreen();
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null || (doc.data()?['name'] ?? '').toString().isEmpty) {
      return const ProfileSetupScreen();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _handleAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Something went wrong: ${snapshot.error}')),
          );
        }

        return snapshot.data!;
      },
    );
  }
}
