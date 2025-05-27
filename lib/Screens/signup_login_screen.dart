import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class SignupLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup / Login'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SignupScreen()));
              },
              child: Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, padding: EdgeInsets.all(16)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent, padding: EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}
