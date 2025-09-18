import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'all_picks_screen.dart';
import 'loading_screen.dart';
import 'picks_screen.dart'; // Import the new screen

// --- Developer Backdoor Flag ---
const bool kDebugBypassLogin = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_hasError) {
      home = const Scaffold(body: Center(child: Text('Error initializing app.')));
    } else if (!_isInitialized) {
      home = const LoadingScreen();
    } else {
      home = const AuthGate();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (kDebugBypassLogin) return const MainScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AuthScreen();
        return const MainScreen();
      },
    );
  }
}

// ========== Main Screen ==========
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick \'em'),
        actions: [
          if (userId != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final isAdmin = data?['role'] == 'admin';
                  if (isAdmin) {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminScreen())),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PicksScreen())),
              child: const Text('My Picks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllPicksScreen())),
              child: const Text('View All Picks'),
            ),
          ],
        ),
      ),
    );
  }
}