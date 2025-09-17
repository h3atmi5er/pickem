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

// ========== Main Screen (Updated with Correct Body) ==========
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick \'em'),
        actions: [
          // --- Secure Admin Button ---
          if (userId != null)
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
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
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // --- FIX: Restored the body with navigation buttons ---
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

// ========== Picks Screen (Rebuilt for Multiple Weeks) ==========
class PicksScreen extends StatefulWidget {
  const PicksScreen({super.key});
  @override
  State<PicksScreen> createState() => _PicksScreenState();
}

class _PicksScreenState extends State<PicksScreen> {
  // State variables
  Map<String, String> _userPicks = {};
  bool _isLocked = false;
  bool _isLoading = true;

  // New state variables for week selection
  List<DropdownMenuItem<String>> _weekMenuItems = [];
  String? _selectedWeekId;

  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  // --- NEW: Fetches all available weeks from Firestore to populate the dropdown ---
  Future<void> _loadAvailableWeeks() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('matches').get();
      if (snapshot.docs.isEmpty) {
        // Handle case where no matches are available at all
        setState(() => _isLoading = false);
        return;
      }

      final weeks = snapshot.docs.map((doc) {
        final weekName = (doc.data())['weekName'] ?? 'Unnamed Week';
        return DropdownMenuItem<String>(
          value: doc.id, // e.g., 'week_1'
          child: Text(weekName), // e.g., 'Week 1'
        );
      }).toList();
      
      setState(() {
        _weekMenuItems = weeks;
        _selectedWeekId = weeks.first.value; // Select the first week by default
      });

      // After finding the weeks, load the data for the default selected week
      if (_selectedWeekId != null) {
        await _loadWeekData(_selectedWeekId!);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- MODIFIED: Loads data for a specific week ---
  Future<void> _loadWeekData(String weekId) async {
    setState(() => _isLoading = true);
    
    // Reset picks for the new week
    _userPicks = {};

    try {
      final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(weekId).get();
      if (matchDoc.exists) {
        setState(() => _isLocked = matchDoc.data()!['isLocked']);
      }

      if (_userId != null) {
        final picksDoc = await FirebaseFirestore.instance.collection('picks').doc(_userId).get();
        if (picksDoc.exists && picksDoc.data()!.containsKey(weekId)) {
          setState(() => _userPicks = Map<String, String>.from(picksDoc.data()![weekId]));
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- MODIFIED: Saves picks for a specific week ---
  Future<void> _savePicks() async {
    if (_userId == null || _selectedWeekId == null) return;
    
    await FirebaseFirestore.instance.collection('picks').doc(_userId).set({
      'displayName': _userEmail,
      _selectedWeekId!: _userPicks, // Use the selected week ID as the key
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Picks saved!'), backgroundColor: Colors.green));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Your Picks'),
        // --- NEW: DropdownButton for week selection ---
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
                    _loadWeekData(newWeekId);
                  }
                },
                dropdownColor: Colors.blueGrey[800],
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: Container(), // Hides the default underline
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: (_userPicks.isNotEmpty && !_isLocked)
          ? FloatingActionButton.extended(
              onPressed: _savePicks,
              label: const Text('Save Picks'),
              icon: const Icon(Icons.save),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedWeekId == null
              ? const Center(child: Text('No weeks available to pick.'))
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('matches').doc(_selectedWeekId!).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: Text('Loading matches...'));
                    
                    final matchData = snapshot.data!.data() as Map<String, dynamic>;
                    final games = List<Map<String, dynamic>>.from(matchData['games']);
                    _isLocked = matchData['isLocked'];

                    if (_isLocked && _userPicks.isEmpty) {
                      return Center(
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

  // Helper widget to build a card for each game (no changes here)
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

  // Helper widget for team icons (reusable) (no changes here)
  Widget _buildTeamIcon({
  required String teamName,
  // required Color color, // REMOVED
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
          // --- MODIFIED: Use a default color for the icon ---
          Icon(Icons.sports_football, color: Colors.grey[700], size: 70),
          const SizedBox(height: 4),
          // Use a SizedBox to constrain the width and allow text wrapping
          SizedBox(
            width: 100,
            child: Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 2, // Allow team names to wrap to a second line
            ),
          ),
        ],
      ),
    ),
  );
}