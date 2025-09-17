// lib/auth_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package.cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ... (Your existing controllers and functions for email/password)

  // --- NEW: Google Sign-In Logic ---
  Future<void> _signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // The user canceled the sign-in

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // After signing in, create a user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  // --- NEW: Helper to create user document on first sign-in ---
  Future<void> _createUserDocument(User user) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userDocRef.get();

    // Only create the document if it doesn't already exist
    if (!doc.exists) {
      userDocRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'role': 'user', // Assign 'user' role by default
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... (Your existing TextFields and email/password buttons)

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // --- NEW: Google Sign-In Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata), // You can use a proper Google logo asset here
              label: const Text('Sign in with Google'),
              onPressed: _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Make sure to also include your existing _emailController, _passwordController,
  // _signUp, and _login methods from your original file.
}