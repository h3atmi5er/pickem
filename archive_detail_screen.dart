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
    // ... (function is unchanged)
  }

  Future<void> _saveWinners() async {
    // ... (function is unchanged)
  }

  Future<void> _promptToFinalizeScores() async {
    // ... (function is unchanged)
  }

  Future<void> _calculateAndFinalizeScores() async {
    // ... (function is unchanged)
  }

  Future<void> _unarchiveWeek() async {
    // ... (function is unchanged)
  }
  
  // ===== NEW FUNCTION TO LOCK A SINGLE MATCH =====
  Future<void> _toggleMatchLock(String gameId, bool newLockState) async {
    setState(() => _isLoading = true);
    final docRef = FirebaseFirestore.instance.collection('archives').doc(widget.archiveId);
    try {
      final doc = await docRef.get();
      if (!doc.exists) return;

      List<Map<String, dynamic>> games = List.from(doc.data()!['games'] ?? []);
      // Find the index of the game to update
      int gameIndex = games.indexWhere((g) => g['gameId'] == gameId);

      if (gameIndex != -1) {
        // Update the lock state for that specific game
        games[gameIndex]['isMatchLocked'] = newLockState;
        // Write the entire updated array back to Firestore
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

                    // Radio button onChanged is now null if the match is locked
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
                            // ADDED INDIVIDUAL MATCH LOCK
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
          ? FloatingActionButton(onPressed: null, child: const CircularProgressIndicator())
          : FloatingActionButton.extended(
              onPressed: _saveWinners,
              label: const Text('Save Winners'),
              icon: const Icon(Icons.save),
            ),
    );
  }

  Widget _buildFinalizedView(Map<String, dynamic> data) {
    // ... (This widget is unchanged)
  }

  Widget _buildSectionTitle(String title) {
    // ... (This widget is unchanged)
  }
}