// lib/make_picks_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'nfl_teams.dart';

class MakePicksScreen extends StatefulWidget {
  const MakePicksScreen({super.key});

  @override
  State<MakePicksScreen> createState() => _MakePicksScreenState();
}

class _MakePicksScreenState extends State<MakePicksScreen> {
  String? _selectedDocId;
  Map<String, String> _userPicks = {};
  bool _isLoading = true;
  List<DropdownMenuItem<String>> _weekMenuItems = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  // This function loads finalized weeks from the 'archives' collection.
  Future<void> _loadAvailableWeeks() async {
    setState(() => _isLoading = true);
    final archivesSnapshot = await FirebaseFirestore.instance
        .collection('archives')
        .orderBy('archivedAt', descending: true)
        .get();

    final List<DropdownMenuItem<String>> weeks = [];

    for (var doc in archivesSnapshot.docs) {
      final weekName = (doc.data())['weekName'] ?? doc.id;
      weeks.add(DropdownMenuItem(value: doc.id, child: Text(weekName)));
    }

    if (mounted) {
      setState(() {
        _weekMenuItems = weeks;
        if (weeks.isNotEmpty) {
          _setSelectedWeek(weeks.first.value!);
        }
        _isLoading = false;
      });
    }
  }

  void _setSelectedWeek(String docId) {
    _selectedDocId = docId;
    _loadUserPicksForWeek(_selectedDocId!);
    setState(() {});
  }

  Future<void> _loadUserPicksForWeek(String weekId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final picksDoc =
        await FirebaseFirestore.instance.collection('picks').doc(userId).get();
    if (picksDoc.exists) {
      final picksData = picksDoc.data()!;
      if (picksData.containsKey(weekId)) {
        _userPicks = Map<String, String>.from(picksData[weekId]);
        setState(() {});
      } else {
        setState(() => _userPicks = {});
      }
    }
  }

  Future<void> _savePicks() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('picks').doc(userId).set({
      _selectedDocId!: _userPicks,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Picks updated! Note: This does not change official scores.'),
        backgroundColor: Colors.blue,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_weekMenuItems.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Adjust My Picks')),
          body: const Center(
              child: Text('There are no finalized weeks to view.')));
    }

    if (_selectedDocId == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Adjust My Picks')),
          body: const Center(child: Text('Please select a week.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('archives')
          .doc(_selectedDocId!)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Week data not found.')));
        }

        final matchData = snapshot.data!.data() as Map<String, dynamic>;
        final games = List<Map<String, dynamic>>.from(matchData['games'] ?? []);

        return Scaffold(
          appBar: AppBar(
            title: DropdownButton<String>(
              value: _selectedDocId,
              items: _weekMenuItems,
              onChanged: (value) => _setSelectedWeek(value!),
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _savePicks,
            label: const Text('Save My Changes'),
            icon: const Icon(Icons.save),
          ),
          body: games.isEmpty
              ? const Center(
                  child: Text('No matches were played this week.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final bool canMakePicks = !(game['isMatchLocked'] ?? false);
                    return _buildGameCard(game, canMakePicks);
                  },
                ),
        );
      },
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, bool canMakePicks) {
    final gameId = game['gameId'];
    final userPick = _userPicks[gameId];
    final actualWinner = game['winner'];

    // MODIFIED: This logic determines the border color based on the match outcome.
    Color getBorderColor(String teamName) {
      // If the match is NOT locked, the border reflects the user's current pick.
      if (canMakePicks) {
        return userPick == teamName ? Colors.blue : Colors.transparent;
      }
      // If the match IS locked, the border reflects the win/loss status.
      else {
        if (actualWinner == null) {
          return Colors.black; // Undecided
        }
        if (actualWinner == teamName) {
          return Colors.green; // Winner
        } else {
          return Colors.red; // Loser
        }
      }
    }

    void updatePick(String teamName) {
      if (canMakePicks) {
        setState(() {
          _userPicks[gameId] = teamName;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This match is locked and picks can no longer be changed.'),
          backgroundColor: Colors.orange,
        ));
      }
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!canMakePicks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Match Locked', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    if (actualWinner != null)
                      Text(' - Winner: $actualWinner', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamIcon(
                  teamName: game['team1Name'],
                  borderColor: getBorderColor(game['team1Name']),
                  onTap: () => updatePick(game['team1Name']),
                  canMakePicks: canMakePicks,
                ),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTeamIcon(
                  teamName: game['team2Name'],
                  borderColor: getBorderColor(game['team2Name']),
                  onTap: () => updatePick(game['team2Name']),
                  canMakePicks: canMakePicks,
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
    required Color borderColor,
    required VoidCallback onTap,
    required bool canMakePicks,
  }) {
    final team = nflTeamsMap[teamName];
    final logoAssetPath = team?.logoAssetPath;
    final Widget teamLogo = logoAssetPath != null
            ? Image.asset(logoAssetPath, height: 80, width: 80)
            : const Icon(Icons.sports_football, size: 80);

    return GestureDetector(
      onTap: canMakePicks ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 4),
          borderRadius: BorderRadius.circular(12),
          // MODIFIED: If the match is locked, the background is white. Otherwise, it's transparent.
          color: canMakePicks ? Colors.transparent : Colors.white,
        ),
        child: teamLogo,
      ),
    );
  }
}