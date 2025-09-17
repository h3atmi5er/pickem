import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'all_picks_screen.dart';
import 'nfl_teams.dart';

// --- Developer Backdoor Flag ---
const bool kDebugBypassLogin = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
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

// In lib/main.dart

// ========== Picks Screen (Corrected Build Logic) ==========
class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});
  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  Map<String, String> _userPicks = {};
  // We can remove the class-level _isLocked, as we'll get it from the stream
  // bool _isLocked = false; 
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
    // This function is correct, no changes needed here.
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
      if (mounted) {
        setState(() {
          _weekMenuItems = weeks;
          _selectedWeekId = weeks.first.value;
        });
      }
      if (_selectedWeekId != null) {
        await _loadWeekData(_selectedWeekId!);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWeekData(String weekId) async {
    // We only need to load the user's picks here now, not the lock status.
    setState(() => _isLoading = true);
    _userPicks = {};
    try {
      if (_userId != null) {
        final picksDoc = await FirebaseFirestore.instance.collection('picks').doc(_userId).get();
        if (picksDoc.exists && picksDoc.data()!.containsKey(weekId)) {
          if (mounted) setState(() => _userPicks = Map<String, String>.from(picksDoc.data()![weekId]));
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
    // The main part of the screen handles loading and week selection...
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_selectedWeekId == null) {
      return const Scaffold(body: Center(child: Text('No weeks available to pick.')));
    }

    // --- FIX: The StreamBuilder now wraps the Scaffold ---
    // This ensures the FAB and body are built with the same, consistent data.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(_selectedWeekId!).snapshots(),
      builder: (context, snapshot) {
        bool isLocked = true; // Default to locked to be safe
        List<Map<String, dynamic>> games = [];

        if (snapshot.hasData && snapshot.data!.exists) {
          final matchData = snapshot.data!.data() as Map<String, dynamic>;
          games = List<Map<String, dynamic>>.from(matchData['games'] ?? []);
          isLocked = matchData['isLocked'] ?? true;
        }

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
                        _loadWeekData(newWeekId); // Load picks for the new week
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
          body: (snapshot.connectionState == ConnectionState.waiting && games.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : (isLocked && _userPicks.isEmpty)
                  ? const Center(
                      child: Text('Picks for this week are locked!',
                          style: TextStyle(fontSize: 20, color: Colors.red)),
                    )
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _buildGameCard(game, isLocked); // Pass lock status down
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