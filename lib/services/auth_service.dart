import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web-specific sign-in
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        // Android/iOS
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return 'Sign in aborted by user';

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }

      // ✅ Save user data to Firestore
      await _saveUserDataToFirestore();
      return null;
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  Future<bool> checkUserProfileExists() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.exists && doc.data()?['gender'] != '';
  }


  Future<void> _saveUserDataToFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'gender': '', // default empty
        'birthdate': null, // can be DateTime later
        'bio': '', // user description
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
