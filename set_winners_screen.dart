// lib/set_winners_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetWinnersScreen extends StatefulWidget {
  final String weekId;
  final VoidCallback? onWinnersSaved; // Add this callback

  const SetWinnersScreen({
    super.key,
    required this.weekId,
    this.onWinnersSaved, // Add to constructor
  });

  @override
  State<SetWinnersScreen> createState() => _SetWinnersScreenState();
}

class _SetWinnersScreenState extends State<SetWinnersScreen> {
  Map<String, String> _winners = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWinners();
  }

  Future<void> _loadCurrentWinners() async {
    final doc = await FirebaseFirestore.instance.collection('matches').doc(widget.weekId).get();
    if (doc.exists) {
      final games = List<Map<String, dynamic>>.from(doc.data()!['games'] ?? []);
      for (var game in games) {
        if (game.containsKey('winner')) {
          _winners[game['gameId']] = game['winner'];
        }
      }
      setState(() {});
    }
  }

  Future<void> _saveWinners() async {
    // Check if a winner is selected for every game
    final doc = await FirebaseFirestore.instance.collection('matches').doc(widget.weekId).get();
    final games = List<Map<String, dynamic>>.from(doc.data()!['games'] ?? []);
    if (_winners.length != games.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a winner for every match.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('matches').doc(widget.weekId);
      final List<Map<String, dynamic>> updatedGames = [];
      final List<Map<String, dynamic>> currentGames = List.from(doc.data()!['games'] ?? []);

      for (var game in currentGames) {
        final gameId = game['gameId'];
        if (_winners.containsKey(gameId)) {
          game['winner'] = _winners[gameId];
        }
        updatedGames.add(game);
      }

      await docRef.update({'games': updatedGames});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Winners saved successfully! Now archiving...'),
          backgroundColor: Colors.blue,
        ));
        
        // Trigger the callback to start the archive process
        widget.onWinnersSaved?.call();

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save winners: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Winners for ${widget.weekId.replaceAll('_', ' ')}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveWinners,
        label: Text(widget.onWinnersSaved != null ? 'Save & Archive' : 'Save Winners'),
        icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').doc(widget.weekId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final games = List<Map<String, dynamic>>.from(data['games'] ?? []);

          if (games.isEmpty) {
            return const Center(child: Text('No matches found for this week.'));
          }

          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final gameId = game['gameId'];
              final team1 = game['team1Name'];
              final team2 = game['team2Name'];
              final currentWinner = _winners[gameId];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Game ${gameId.replaceAll('game', '')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('$team1 vs $team2', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      RadioListTile<String>(
                        title: Text(team1),
                        value: team1,
                        groupValue: currentWinner,
                        onChanged: (value) => setState(() => _winners[gameId] = value!),
                      ),
                      RadioListTile<String>(
                        title: Text(team2),
                        value: team2,
                        groupValue: currentWinner,
                        onChanged: (value) => setState(() => _winners[gameId] = value!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}