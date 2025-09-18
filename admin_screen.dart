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
  // REMOVED _toggleLock function

  Future<void> _removeGame(String weekId, Map<String, dynamic> gameToRemove) async {
    // ... (function is unchanged)
  }

  Future<void> _deleteWeek(BuildContext context, String weekId) async {
    // ... (function is unchanged)
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
                    // 'isLocked' field is no longer needed here
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
    // ... (function is unchanged)
  }

  Future<void> _archiveWeek(BuildContext context, String weekId, Map<String, dynamic> weekData) async {
    // ... (function is unchanged)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Weeks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'View Archives',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // ... (functionality is unchanged)
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final weekDocs = snapshot.data!.docs;
          if (weekDocs.isEmpty)
            return const Center(child: Text('No active weeks found.'));

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
                        // ... (Rename and Delete buttons are unchanged)
                      ),
                      // REMOVED the "Lock Picks" Switch Row
                      ExpansionTile(
                        // ... (This section is unchanged)
                      ),
                      // ... (Rest of the buttons are unchanged)
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