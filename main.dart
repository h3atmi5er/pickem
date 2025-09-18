// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'all_picks_screen.dart';
import 'loading_screen.dart';
import 'picks_screen.dart';
import 'make_picks_screen.dart';
import 'profile_screen.dart';
import 'display_name_screen.dart';

// --- Developer Backdoor Flag ---
const bool kDebugBypassLogin = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ... (MyApp and AuthGate widgets are unchanged)
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
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (_hasError) {
      home = const Scaffold(
          body: Center(child: Text('Error initializing app.')));
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
        if (!snapshot.hasData) {
          return const AuthScreen();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }
            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              return const AuthScreen();
            }

            final userData =
                userDocSnapshot.data!.data() as Map<String, dynamic>;
            final displayNameSet = userData['displayNameSet'] ?? false;

            if (displayNameSet) {
              return const MainScreen();
            } else {
              return const DisplayNameScreen();
            }
          },
        );
      },
    );
  }
}

// ========== Main Screen ==========
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick \'em'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          if (userId != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final isAdmin = data?['role'] == 'admin';
                  if (isAdmin) {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminScreen())),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CurrentWeekRecord(),
            const SizedBox(height: 12),
            if (userId != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Record: 0-0', style: TextStyle(fontSize: 24));
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final wins = userData['totalWins'] ?? 0;
                  final losses = userData['totalLosses'] ?? 0;

                  return Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      child: Column(
                        children: [
                          Text(
                            'Overall Record',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$wins - $losses',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MakePicksScreen())),
              child: const Text('Make My Picks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllPicksScreen())),
              child: const Text('View Everyone\'s Picks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PicksScreen())),
              child: const Text('View Completed Weeks'),
            ),
          ],
        ),
      ),
    );
  }
}

// MODIFIED: The CurrentWeekRecord widget has been rewritten to use the designated active week.
class CurrentWeekRecord extends StatelessWidget {
  const CurrentWeekRecord({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    // 1. Listen to the app_status document to find out which week is active.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('app_status').doc('status').snapshots(),
      builder: (context, statusSnapshot) {
        if (!statusSnapshot.hasData || !statusSnapshot.data!.exists) {
          return const SizedBox.shrink(); // No active week has been set by the admin.
        }
        final activeWeekId = statusSnapshot.data!['activeWeekId'];
        if (activeWeekId == null || activeWeekId == '') {
          return const SizedBox.shrink(); // Active week ID is not set.
        }

        // 2. Listen to the specific active week document in the 'matches' collection.
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('matches').doc(activeWeekId).snapshots(),
          builder: (context, weekSnapshot) {
            if (!weekSnapshot.hasData || !weekSnapshot.data!.exists) {
              return const SizedBox.shrink(); // The designated active week doesn't exist in 'matches'.
            }

            final weekData = weekSnapshot.data!.data() as Map<String, dynamic>;
            final weekName = weekData['weekName'] ?? 'Current Week';

            // 3. Listen to the user's picks to calculate the record.
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('picks').doc(userId).snapshots(),
              builder: (context, picksSnapshot) {
                if (!picksSnapshot.hasData || !picksSnapshot.data!.exists) {
                  return _buildRecordCard(context, weekName, 0, 0);
                }

                final picksData = picksSnapshot.data!.data() as Map<String, dynamic>;
                if (!picksData.containsKey(activeWeekId)) {
                  return _buildRecordCard(context, weekName, 0, 0);
                }

                final weeklyPicks = Map<String, String>.from(picksData[activeWeekId]);
                final games = List<Map<String, dynamic>>.from(weekData['games'] ?? []);
                int weeklyWins = 0;
                int weeklyLosses = 0;

                final winnersMap = {for (var g in games) g['gameId']: g['winner']};

                weeklyPicks.forEach((gameId, pickedTeam) {
                  final winner = winnersMap[gameId];
                  if (winner != null) {
                    if (pickedTeam == winner) {
                      weeklyWins++;
                    } else {
                      weeklyLosses++;
                    }
                  }
                });

                return _buildRecordCard(context, weekName, weeklyWins, weeklyLosses);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecordCard(BuildContext context, String weekName, int wins, int losses) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Column(
          children: [
            Text(
              weekName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$wins - $losses',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}