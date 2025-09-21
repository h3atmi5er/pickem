// lib/manage_weeks_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_match_screen.dart';

class ManageWeeksScreen extends StatefulWidget {
  const ManageWeeksScreen({super.key});

  @override
  State<ManageWeeksScreen> createState() => _ManageWeeksScreenState();
}

class _ManageWeeksScreenState extends State<ManageWeeksScreen> {
  Future<void> _removeGame(
      String weekId, Map<String, dynamic> gameToRemove) async {
    final weekRef =
        FirebaseFirestore.instance.collection('matches').doc(weekId);
    await weekRef.update({
      'games': FieldValue.arrayRemove([gameToRemove])
    });
  }

  Future<void> _deleteWeek(BuildContext context, String weekId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
            'This will permanently delete "$weekId". This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('matches').doc(weekId).delete();
    }
  }

  void _showAddWeekDialog(BuildContext context) async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('matches').get();
    final nextWeekNumber = querySnapshot.docs.length + 1;
    final TextEditingController nameController =
        TextEditingController(text: 'Week $nextWeekNumber');

    if (!context.mounted) return;
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
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Weeks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeekDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Week'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .orderBy(FieldPath.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No active weeks found. Add a new week to get started.'));
          }

          final weekDocs = snapshot.data!.docs;

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(weekName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold))),
                          Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showRenameDialog(
                                      context, weekId, weekName),
                                  tooltip: 'Rename Week'),
                              IconButton(
                                  icon:
                                      const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteWeek(context, weekId),
                                  tooltip: 'Delete Week'),
                            ],
                          )
                        ],
                      ),
                      ExpansionTile(
                        title: Text('${games.length} Matches'),
                        children: games
                            .map((game) => ListTile(
                                  title: Text(
                                      '${game['team1Name']} vs ${game['team2Name']}'),
                                  trailing: IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () =>
                                          _removeGame(weekId, game)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Match'),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AddMatchScreen(weekId: weekId)))),
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