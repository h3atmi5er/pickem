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

  // This function loads only active weeks from the 'matches' collection
  Future<void> _loadAvailableWeeks() async {
    setState(() => _isLoading = true);
    final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
    
    final List<DropdownMenuItem<String>> weeks = [];
    final sortedMatches = matchesSnapshot.docs..sort((a, b) => a.id.compareTo(b.id));

    for (var doc in sortedMatches) {
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
    final picksDoc = await FirebaseFirestore.instance.collection('picks').doc(userId).get();
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
        content: Text('Picks saved!'),
        backgroundColor: Colors.green,
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
        appBar: AppBar(title: const Text('Make My Picks')),
        body: const Center(child: Text('There are no active weeks to make picks for.'))
      );
    }

    if (_selectedDocId == null) {
       return Scaffold(
        appBar: AppBar(title: const Text('Make My Picks')),
        body: const Center(child: Text('Please select a week.'))
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(_selectedDocId!).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('Week data not found.')));
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
          floatingActionButton: (_userPicks.isNotEmpty)
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
                        return _buildGameCard(game, true);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, bool canMakePicks) {
    final gameId = game['gameId'];
    final userPick = _userPicks[gameId];
    
    Color getBorderColor(String teamName) {
      if (userPick == teamName) {
        return Colors.blue;
      }
      return Colors.transparent;
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamIcon(
                  teamName: game['team1Name'],
                  borderColor: getBorderColor(game['team1Name']),
                  onTap: () => setState(() => _userPicks[gameId] = game['team1Name']),
                  canMakePicks: canMakePicks,
                ),
                const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                _buildTeamIcon(
                  teamName: game['team2Name'],
                  borderColor: getBorderColor(game['team2Name']),
                  onTap: () => setState(() => _userPicks[gameId] = game['team2Name']),
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
    return GestureDetector(
      onTap: canMakePicks ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: logoAssetPath != null
            ? Image.asset(logoAssetPath, height: 80, width: 80)
            : const Icon(Icons.sports_football, size: 80),
      ),
    );
  }
}