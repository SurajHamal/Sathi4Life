import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sathi4life/screens/AuthGate.dart';

// Import your screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/swipe_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(PresenceHandler(child: Sathi4LifeApp()));
}

// Handles user's online presence
class PresenceHandler extends StatefulWidget {
  final Widget child;
  PresenceHandler({required this.child});

  @override
  _PresenceHandlerState createState() => _PresenceHandlerState();
}

class _PresenceHandlerState extends State<PresenceHandler> with WidgetsBindingObserver {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for auth state changes to detect current user
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        currentUser = user;
      });

      if (user != null) {
        _setOnlineStatus(true);
      }
    });
  }

  @override
  void dispose() {
    _setOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    try {
      await userDoc.update({'isOnline': isOnline});
    } catch (e) {
      await userDoc.set({'isOnline': isOnline}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class Sathi4LifeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sathi4Life',
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // Entry screen
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/signup': (context) => SignupScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profileSetup': (context) => const ProfileSetupScreen(),
        '/chats': (context) => ChatListScreen(),
        '/swipe': (context) => const SwipeScreen(),
        '/chat_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatDetailScreen(
            chatId: args['chatId'],
            otherUserName: args['otherUserName'],
            otherUserId: args['otherUserId'],
          );
        },
      },
    );
  }
}
