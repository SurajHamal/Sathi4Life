import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/modern_google_button.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signUp(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await checkUserProfile(context, user);
      }
    } else {
      setState(() => _errorMessage = result);
    }
  }

  Future<void> signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (result == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await checkUserProfile(context, user);
      }
    } else {
      setState(() => _errorMessage = result);
    }
  }

  Future<void> checkUserProfile(BuildContext context, User user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/profileSetup');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with faded overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // Signup Form
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sathi4Life',
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: MediaQuery.sizeOf(context).width > 600 ? 48 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.amberAccent,
                      shadows: const [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Create an Account',
                    style: GoogleFonts.lobsterTwo(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.red),
                      prefixIcon: const Icon(Icons.email, color: Colors.red),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter email';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Enter a valid email';
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.red),
                      prefixIcon: const Icon(Icons.lock, color: Colors.red),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: signup,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Sign Up'),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('OR', style: TextStyle(color: Colors.white)),
                      ),
                      Expanded(child: Divider(color: Colors.white)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (!_isLoading)
                    ModernGoogleButton(
                      onPressed: signUpWithGoogle,
                      isLoading: _isLoading,
                    ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: Colors.white)),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
