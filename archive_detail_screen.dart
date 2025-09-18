// lib/archive_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArchiveDetailScreen extends StatefulWidget {
  final String archiveId;
  const ArchiveDetailScreen({super.key, required this.archiveId});

  @override
  State<ArchiveDetailScreen> createState() => _ArchiveDetailScreenState();
}

class _ArchiveDetailScreenState extends State<ArchiveDetailScreen> {
  Map<String, String?> _winners = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWinners();
  }

  Future<void> _loadCurrentWinners() async {
    final doc = await FirebaseFirestore.instance.collection('archives').doc(widget.archiveId).get();
    if (!doc.exists) return;

    final games = List<Map<String, dynamic>>.from(doc.data()!['games'] ?? []);
    final Map<String, String?> loadedWinners = {};
    for (var game in games) {
      loadedWinners[game['gameId']] = game['winner'];
    }
    setState(() => _winners = loadedWinners);
  }

  Future<void> _saveWinners() async {
    setState(() => _isLoading = true);
    final docRef = FirebaseFirestore.instance.collection('archives').doc(widget.archiveId);
    try {
      final doc = await docRef.get();
      if (!doc.exists) return;

      List<Map<String, dynamic>> games = List.from(doc.data()!['games'] ?? []);
      for (int i = 0; i < games.length; i++) {
        final gameId = games[i]['gameId'];
        if (_winners.containsKey(gameId)) {
          games[i]['winner'] = _winners[gameId];
        }
      }
      await docRef.update({'games': games});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Winners saved!'), backgroundColor: Colors.green,));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptToFinalizeScores() async {
     final bool allWinnersSet = !_winners.containsValue(null);
    if (!allWinnersSet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('All winners must be set before finalizing.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Finalize Scores?'),
              content: const Text(
                  'This will calculate wins/losses for all users for this week. This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Finalize', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
              ],
            ));

    if (confirmed == true) {
      _calculateAndFinalizeScores();
    }
  }

  Future<void> _calculateAndFinalizeScores() async {
    setState(() => _isLoading = true);

    try {
      final picksSnapshot = await FirebaseFirestore.instance.collection('picks').get();
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      for (final userPickDoc in picksSnapshot.docs) {
        final userPickData = userPickDoc.data();
        if (userPickData.containsKey(widget.archiveId)) {
          final weekPicks = Map<String, String>.from(userPickData[widget.archiveId]);
          int wins = 0;
          int losses = 0;

          weekPicks.forEach((gameId, pickedTeam) {
            if (_winners.containsKey(gameId) && _winners[gameId] != null) {
              if (pickedTeam == _winners[gameId]) {
                wins++;
              } else {
                losses++;
              }
            }
          });

          final userStatsRef = FirebaseFirestore.instance.collection('users').doc(userPickDoc.id);
          batch.update(userStatsRef, {
            'totalWins': FieldValue.increment(wins),
            'totalLosses': FieldValue.increment(losses),
          });

          batch.update(FirebaseFirestore.instance.collection('archives').doc(widget.archiveId), {
            'scores.${userPickDoc.id}': {'wins': wins, 'losses': losses, 'displayName': userPickData['displayName']}
          });
        }
      }

      batch.update(FirebaseFirestore.instance.collection('archives').doc(widget.archiveId), {'isFinalized': true});
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scores finalized successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finalizing scores: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unarchiveWeek() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive Week?'),
        content: const Text('This will move the week back to the active list. Finalized scores will NOT be reversed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unarchive')),
        ],
      )
    );

    if (confirmed == true) {
      final doc = await FirebaseFirestore.instance.collection('archives').doc(widget.archiveId).get();
      if (doc.exists) {
        final data = doc.data()!;
        await FirebaseFirestore.instance.collection('matches').doc(widget.archiveId).set(data);
        await FirebaseFirestore.instance.collection('archives').doc(widget.archiveId).delete();
        if(mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleMatchLock(String gameId, bool newLockState) async {
    setState(() => _isLoading = true);
    final docRef = FirebaseFirestore.instance.collection('archives').doc(widget.archiveId);
    try {
      final doc = await docRef.get();
      if (!doc.exists) return;

      List<Map<String, dynamic>> games = List.from(doc.data()!['games'] ?? []);
      int gameIndex = games.indexWhere((g) => g['gameId'] == gameId);

      if (gameIndex != -1) {
        games[gameIndex]['isMatchLocked'] = newLockState;
        await docRef.update({'games': games});
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating lock: $e')));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.archiveId.replaceAll('_', ' ')),
        actions: [
          IconButton(
            icon: const Icon(Icons.unarchive),
            tooltip: 'Unarchive Week',
            onPressed: _unarchiveWeek,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('archives').doc(widget.archiveId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('This week may have been unarchived.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final games = List<Map<String, dynamic>>.from(data['games'] ?? []);
          final isFinalized = data['isFinalized'] ?? false;

          if (isFinalized) {
            return _buildFinalizedView(data);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final gameId = game['gameId'];
                    final bool isMatchLocked = game['isMatchLocked'] ?? false;

                    final onChangedCallback = isMatchLocked
                        ? null
                        : (String? val) => setState(() => _winners[gameId] = val);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text('${game['team1Name']} vs ${game['team2Name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            RadioListTile<String?>(
                              title: Text(game['team1Name']),
                              value: game['team1Name'],
                              groupValue: _winners[gameId],
                              onChanged: onChangedCallback,
                            ),
                            RadioListTile<String?>(
                              title: Text(game['team2Name']),
                              value: game['team2Name'],
                              groupValue: _winners[gameId],
                              onChanged: onChangedCallback,
                            ),
                            RadioListTile<String?>(
                              title: const Text('Undecided', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              value: null,
                              groupValue: _winners[gameId],
                              onChanged: onChangedCallback,
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Text('Lock Match', style: TextStyle(fontSize: 16)),
                                ),
                                Switch(
                                  value: isMatchLocked,
                                  onChanged: (value) => _toggleMatchLock(gameId, value),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isLoading
          ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator())
          : Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                onPressed: _saveWinners,
                label: const Text('Save Winners'),
                icon: const Icon(Icons.save),
                heroTag: 'save_winners_fab',
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                onPressed: _promptToFinalizeScores,
                label: const Text('Finalize Scores'),
                icon: const Icon(Icons.check_circle),
                backgroundColor: Colors.green,
                heroTag: 'finalize_scores_fab',
              ),
            ],
          )
    );
  }

  Widget _buildFinalizedView(Map<String, dynamic> data) {
    final scores = Map<String, dynamic>.from(data['scores'] ?? {});
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => (b.value['wins'] as int).compareTo(a.value['wins'] as int));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Scores Finalized'),
        ...sortedScores.map((entry) {
          final scoreData = entry.value;
          return Card(
            child: ListTile(
              title: Text(scoreData['displayName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('${scoreData['wins']} - ${scoreData['losses']}', style: const TextStyle(fontSize: 16)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}