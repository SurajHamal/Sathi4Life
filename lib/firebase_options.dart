import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sathi4life/main.dart';
import 'firebase_options.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    runApp(Sathi4LifeApp());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Sathi4LifeApp());
}
