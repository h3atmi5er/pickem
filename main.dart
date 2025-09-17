import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'all_picks_screen.dart';
import 'nfl_teams.dart';
import 'loading_screen.dart'; // --- FIX: Import is now at the top ---

// --- Developer Backdoor Flag ---
const bool kDebugBypassLogin = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// --- MODIFIED: MyApp now manages the app's initialization state ---
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
      // Show the scrolling logo screen while initializing
      home = const LoadingScreen();
    } else {
      // Once initialized, show the AuthGate
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

// ========== Picks Screen ==========
class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});
  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  Map<String, String> _userPicks = {};
  bool _isLoading = true;
  List<DropdownMenuItem<String>> _weekMenuItems = [];
  String? _selectedWeekId;

  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('matches').get();
      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final weeks = snapshot.docs.map((doc) {
        final weekName = (doc.data())['weekName'] ?? 'Unnamed Week';
        return DropdownMenuItem<String>(
          value: doc.id,
          child: Text(weekName),
        );
      }).toList();

      weeks.sort((a, b) {
        final weekNumA = int.tryParse(a.value!.replaceAll('week_', '')) ?? 0;
        final weekNumB = int.tryParse(b.value!.replaceAll('week_', '')) ?? 0;
        return weekNumA.compareTo(weekNumB);
      });

      if (mounted) {
        setState(() {
          _weekMenuItems = weeks;
          _selectedWeekId = weeks.first.value;
        });
      }
      if (_selectedWeekId != null) {
        await _loadUserPicksForWeek(_selectedWeekId!);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserPicksForWeek(String weekId) async {
    setState(() => _isLoading = true);
    _userPicks = {};
    try {
      if (_userId != null) {
        final picksDoc = await FirebaseFirestore.instance.collection('picks').doc(_userId).get();
        if (picksDoc.exists && picksDoc.data()!.containsKey(weekId)) {
          if (mounted) {
            setState(() => _userPicks = Map<String, String>.from(picksDoc.data()![weekId]));
          }
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePicks() async {
    if (_userId == null || _selectedWeekId == null) return;
    await FirebaseFirestore.instance.collection('picks').doc(_userId).set({
      'displayName': _userEmail,
      _selectedWeekId!: _userPicks,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Picks saved!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_selectedWeekId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Make Your Picks')),
        body: const Center(child: Text('No weeks have been created by the admin yet.'))
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(_selectedWeekId!).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('This week could not be found.')));
        }

        final matchData = snapshot.data!.data() as Map<String, dynamic>;
        final games = List<Map<String, dynamic>>.from(matchData['games'] ?? []);
        final isLocked = matchData['isLocked'] ?? true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Make Your Picks'),
            actions: [
              if (_weekMenuItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: DropdownButton<String>(
                    value: _selectedWeekId,
                    items: _weekMenuItems,
                    onChanged: (newWeekId) {
                      if (newWeekId != null) {
                        setState(() => _selectedWeekId = newWeekId);
                        _loadUserPicksForWeek(newWeekId);
                      }
                    },
                    dropdownColor: Colors.blueGrey[800],
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
            ],
          ),
          floatingActionButton: (_userPicks.isNotEmpty && !isLocked)
              ? FloatingActionButton.extended(
                  onPressed: _savePicks,
                  label: const Text('Save Picks'),
                  icon: const Icon(Icons.save),
                )
              : null,
          body: (isLocked && _userPicks.isEmpty)
              ? const Center(
                  child: Text('Picks for this week are locked!',
                      style: TextStyle(fontSize: 20, color: Colors.red)),
                )
              : games.isEmpty
                  ? const Center(child: Text('The admin has not added any matches for this week yet.'))
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _buildGameCard(game, isLocked);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, bool isLocked) {
    final gameId = game['gameId'];
    final selectedWinner = _userPicks[gameId];
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Game ${gameId.replaceAll('game', '')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamIcon(
                  teamName: game['team1Name'],
                  isSelected: selectedWinner == game['team1Name'],
                  onTap: () => setState(() => _userPicks[gameId] = game['team1Name']),
                  isLocked: isLocked,
                ),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTeamIcon(
                  teamName: game['team2Name'],
                  isSelected: selectedWinner == game['team2Name'],
                  onTap: () => setState(() => _userPicks[gameId] = game['team2Name']),
                  isLocked: isLocked,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamIcon({
    required String teamName,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLocked,
  }) {
    final team = nflTeamsMap[teamName];
    final logoAssetPath = team?.logoAssetPath;
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Colors.green : Colors.transparent, width: 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (logoAssetPath != null)
              Image.asset(
                logoAssetPath,
                height: 70,
                width: 70,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.sports_football, color: Colors.grey, size: 70);
                },
              )
            else
              const Icon(Icons.sports_football, color: Colors.grey, size: 70),
            const SizedBox(height: 4),
            SizedBox(
              width: 100,
              child: Text(
                teamName,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}