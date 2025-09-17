import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth_screen.dart';
import 'admin_screen.dart'; // Import new screens
import 'all_picks_screen.dart';

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

// ========== Main Screen (Updated) ==========
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick \'em'),
        actions: [
          // Button to navigate to the Admin Screen
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminScreen())),
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

// ========== Picks Screen (Completely Rebuilt) ==========
class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});
  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  // Store picks as a map: { 'game1': 'Red Team', 'game2': 'Green Team' }
  Map<String, String> _userPicks = {};
  bool _isLocked = false;
  bool _isLoading = true;

  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final matchDoc = await FirebaseFirestore.instance.collection('matches').doc('current_week').get();
    if (matchDoc.exists) {
      setState(() => _isLocked = matchDoc.data()!['isLocked']);
    }

    if (_userId != null) {
      final picksDoc = await FirebaseFirestore.instance.collection('picks').doc(_userId).get();
      if (picksDoc.exists && picksDoc.data()!.containsKey('current_week')) {
        setState(() => _userPicks = Map<String, String>.from(picksDoc.data()!['current_week']));
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _savePicks() async {
    if (_userId == null) return;
    await FirebaseFirestore.instance.collection('picks').doc(_userId).set({
      'displayName': _userEmail, // Save user's email for display
      'current_week': _userPicks,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Picks saved!'), backgroundColor: Colors.green));
    Navigator.of(context).pop(); // Go back to the main screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Your Picks')),
      floatingActionButton: (_userPicks.isNotEmpty && !_isLocked)
          ? FloatingActionButton.extended(
              onPressed: _savePicks,
              label: const Text('Save Picks'),
              icon: const Icon(Icons.save),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').doc('current_week').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Text('Loading matches...'));

                final matchData = snapshot.data!.data() as Map<String, dynamic>;
                final games = List<Map<String, dynamic>>.from(matchData['games']);
                _isLocked = matchData['isLocked'];

                if (_isLocked && _userPicks.isEmpty) {
                  return const Center(
                    child: Text('Picks for this week are locked!',
                        style: TextStyle(fontSize: 20, color: Colors.red)),
                  );
                }

                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return _buildGameCard(game);
                  },
                );
              },
            ),
    );
  }

  // Helper widget to build a card for each game
  Widget _buildGameCard(Map<String, dynamic> game) {
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
                  color: Color(int.parse('0xFF${game['team1Color']}')),
                  isSelected: selectedWinner == game['team1Name'],
                  onTap: () => setState(() => _userPicks[gameId] = game['team1Name']),
                ),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTeamIcon(
                  teamName: game['team2Name'],
                  color: Color(int.parse('0xFF${game['team2Color']}')),
                  isSelected: selectedWinner == game['team2Name'],
                  onTap: () => setState(() => _userPicks[gameId] = game['team2Name']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for team icons (reusable)
  Widget _buildTeamIcon({
    required String teamName,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLocked ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? Colors.green : Colors.transparent, width: 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.sports_football, color: color, size: 70),
            Text(teamName),
          ],
        ),
      ),
    );
  }
}