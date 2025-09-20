import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sathi4life/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sathi4life/firebase_options.dart'; // Make sure this exists

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('Login screen shows all required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );

    // Expect to find email and password fields and sign-in button
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? "), findsOneWidget);
  });
}
