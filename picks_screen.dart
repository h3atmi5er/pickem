// lib/picks_screen.dart
import 'package:flutter/material.dart';
// ... other imports

class _PicksScreenState extends State<PicksScreen> {
  // ... (state variables are unchanged)

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    // ... (function is unchanged)
  }
  
  void _setSelectedWeek(String compositeId) {
    // ... (function is unchanged)
  }

  Future<void> _loadUserPicksForWeek(String weekId) async {
    // ... (function is unchanged)
  }

  Future<void> _savePicks() async {
    // ... (function is unchanged)
  }

  @override
  Widget build(BuildContext context) {
    // ... (initial loading and error views are unchanged)

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(_selectedCollection).doc(_selectedDocId!).snapshots(),
      builder: (context, snapshot) {
        // ... (snapshot error handling is unchanged)

        final matchData = snapshot.data!.data() as Map<String, dynamic>;
        final games = List<Map<String, dynamic>>.from(matchData['games'] ?? []);
        
        // NEW, SIMPLER LOGIC FOR WHETHER PICKS CAN BE MADE
        final bool canMakePicks = _selectedCollection == 'matches';

        return Scaffold(
          appBar: AppBar(
            // ... (app bar is unchanged)
          ),
          // MODIFIED FLOATING ACTION BUTTON LOGIC
          floatingActionButton: (_userPicks.isNotEmpty && canMakePicks)
              ? FloatingActionButton.extended(
                  onPressed: _savePicks,
                  label: const Text('Save Picks'),
                  icon: const Icon(Icons.save),
                )
              : null,
          body: games.isEmpty
                  ? const Center(child: Text('No matches have been added for this week yet.'))
                  : ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        // Pass the simplified boolean down
                        return _buildGameCard(game, canMakePicks);
                      },
                    ),
        );
      },
    );
  }

  // MODIFIED to accept canMakePicks
  Widget _buildGameCard(Map<String, dynamic> game, bool canMakePicks) {
    final gameId = game['gameId'];
    final userPick = _userPicks[gameId];
    final actualWinner = game['winner'];

    Color getBorderColor(String teamName) {
      // ... (this function is unchanged)
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... (VS text is unchanged)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamIcon(
                  teamName: game['team1Name'],
                  borderColor: getBorderColor(game['team1Name']),
                  onTap: () => setState(() => _userPicks[gameId] = game['team1Name']),
                  // Use the new boolean here
                  canMakePicks: canMakePicks,
                ),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTeamIcon(
                  teamName: game['team2Name'],
                  borderColor: getBorderColor(game['team2Name']),
                  onTap: () => setState(() => _userPicks[gameId] = game['team2Name']),
                  // And here
                  canMakePicks: canMakePicks,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED to accept canMakePicks
  Widget _buildTeamIcon({
    required String teamName,
    required Color borderColor,
    required VoidCallback onTap,
    required bool canMakePicks,
  }) {
    final team = nflTeamsMap[teamName];
    final logoAssetPath = team?.logoAssetPath;
    return GestureDetector(
      // Tapping is disabled if canMakePicks is false
      onTap: canMakePicks ? onTap : null,
      child: Container(
        // ... (rest of the widget is unchanged)
      ),
    );
  }
}