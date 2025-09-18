// lib/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_match_screen.dart';
import 'archive_screen.dart';
import 'set_winners_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  Future<void> _removeGame(String weekId, Map<String, dynamic> gameToRemove) async {
    final weekRef = FirebaseFirestore.instance.collection('matches').doc(weekId);
    await weekRef.update({
      'games': FieldValue.arrayRemove([gameToRemove])
    });
  }

  Future<void> _deleteWeek(BuildContext context, String weekId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('This will permanently delete "$weekId". This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('matches').doc(weekId).delete();
    }
  }

  void _showAddWeekDialog(BuildContext context, int nextWeekNumber) {
    final TextEditingController nameController =
        TextEditingController(text: 'Week $nextWeekNumber');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Week'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter week name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('matches')
                      .doc('week_$nextWeekNumber')
                      .set({
                    'weekName': newName,
                    'games': [],
                  });
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(
      BuildContext context, String weekId, String currentName) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Rename Week'),
              content: TextField(controller: nameController),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('matches')
                          .doc(weekId)
                          .update({'weekName': nameController.text.trim()});
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Save')),
              ],
            ));
  }
  
  // MODIFIED: Renamed function and updated dialog text
  Future<void> _finalizeAndMoveWeek(BuildContext context, String weekId, Map<String, dynamic> weekData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize and Move Week?'),
        content: const Text('This will move the week to the public "Completed Weeks" section. You can finalize scores from there.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Finalize & Move')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('archives').doc(weekId).set({
        ...weekData,
        'archivedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('matches').doc(weekId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Active Weeks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            // MODIFIED: Tooltip text updated
            tooltip: 'Manage Completed Weeks',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
           final querySnapshot = await FirebaseFirestore.instance.collection('matches').get();
           _showAddWeekDialog(context, querySnapshot.docs.length + 1);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Week'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy(FieldPath.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final weekDocs = snapshot.data!.docs;
          if (weekDocs.isEmpty) {
            return const Center(child: Text('No active weeks found. Add a new week to get started.'));
          }

          return ListView.builder(
            itemCount: weekDocs.length,
            itemBuilder: (context, index) {
              final weekDoc = weekDocs[index];
              final data = weekDoc.data() as Map<String, dynamic>;
              final weekId = weekDoc.id;
              final weekName = data['weekName'] ?? 'Unnamed Week';
              final List<dynamic> games = data['games'] ?? [];

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(weekName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _showRenameDialog(context, weekId, weekName), tooltip: 'Rename Week'),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteWeek(context, weekId), tooltip: 'Delete Week'),
                            ],
                          )
                        ],
                      ),
                      ExpansionTile(
                        title: Text('${games.length} Matches'),
                        children: games.map((game) => ListTile(
                          title: Text('${game['team1Name']} vs ${game['team2Name']}'),
                          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeGame(weekId, game)),
                        )).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Add Match'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMatchScreen(weekId: weekId)))),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.archive),
                            // MODIFIED: Button text
                            label: const Text('Finalize & Move'),
                            // MODIFIED: Function call
                            onPressed: () => _finalizeAndMoveWeek(context, weekId, data),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ],
                      )
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