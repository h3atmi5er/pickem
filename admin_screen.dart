// lib/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_match_screen.dart';
import 'archive_screen.dart';

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

  Future<void> _setActiveWeek(String weekId) async {
    // Set the document with merge: true to avoid errors if it doesn't exist.
    await FirebaseFirestore.instance.collection('app_status').doc('status').set({
      'activeWeekId': weekId,
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$weekId is now the active week.'), backgroundColor: Colors.green),
      );
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('app_status').doc('status').snapshots(),
        builder: (context, statusSnapshot) {
          // If the status document is still loading, show a progress indicator.
          if (statusSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String? activeWeekId;
          // CORRECTED: This logic is now much safer and handles all possible null/error states.
          if (statusSnapshot.hasData && statusSnapshot.data!.exists) {
            final statusData = statusSnapshot.data!.data() as Map<String, dynamic>?;
            activeWeekId = statusData?['activeWeekId'];
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .orderBy(FieldPath.documentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No active weeks found. Add a new week to get started.'));
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
                  final bool isActive = weekId == activeWeekId;

                  return Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 4,
                    shape: isActive
                      ? RoundedRectangleBorder(side: const BorderSide(color: Colors.green, width: 2), borderRadius: BorderRadius.circular(12))
                      : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (isActive)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Icon(Icons.star, color: Colors.green),
                                    ),
                                  Flexible(child: Text(weekName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                ],
                              ),
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
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Set Active'),
                                onPressed: isActive ? null : () => _setActiveWeek(weekId),
                                style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.grey : Colors.green),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.archive),
                                label: const Text('Finalize'),
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
          );
        }
      ),
    );
  }
}