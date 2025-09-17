// lib/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_match_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _toggleLock(String weekId, bool isCurrentlyLocked) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(weekId)
        .update({'isLocked': !isCurrentlyLocked});
  }

  Future<void> _removeGame(String weekId, Map<String, dynamic> gameToRemove) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(weekId)
        .update({
      'games': FieldValue.arrayRemove([gameToRemove])
    });
  }
  
  Future<void> _deleteWeek(BuildContext context, String weekId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This will permanently delete the entire week and all its matches. This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('matches').doc(weekId).delete();
    }
  }

  void _showAddWeekDialog(BuildContext context, int nextWeekNumber) {
    final TextEditingController nameController = TextEditingController(text: 'Week $nextWeekNumber');
    
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
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('matches')
                      .doc('week_$nextWeekNumber')
                      .set({
                        'weekName': newName,
                        'isLocked': false,
                        'games': [],
                      });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  void _showRenameDialog(BuildContext context, String weekId, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Week'),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Enter new week name')),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance.collection('matches').doc(weekId).update({'weekName': newName});
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Weeks')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Week'),
        // --- THIS IS THE CORRECTED LOGIC ---
        onPressed: () async {
          final querySnapshot = await FirebaseFirestore.instance.collection('matches').get();
          int maxWeekNum = 0;
          // Find the highest week number from the document IDs
          for (var doc in querySnapshot.docs) {
            final weekNum = int.tryParse(doc.id.replaceAll('week_', '')) ?? 0;
            if (weekNum > maxWeekNum) {
              maxWeekNum = weekNum;
            }
          }
          // The next week is the highest number + 1
          _showAddWeekDialog(context, maxWeekNum + 1);
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').orderBy(FieldPath.documentId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final weekDocs = snapshot.data!.docs;
          if (weekDocs.isEmpty) return const Center(child: Text('No weeks found. Add one to get started!'));

          return ListView.builder(
            itemCount: weekDocs.length,
            itemBuilder: (context, index) {
              final weekDoc = weekDocs[index];
              final data = weekDoc.data() as Map<String, dynamic>;
              final weekId = weekDoc.id;
              final bool isLocked = data['isLocked'] ?? false;
              final weekName = data['weekName'] ?? 'Unnamed Week';
              final List<dynamic> games = data['games'] ?? [];

              return Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(weekName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _showRenameDialog(context, weekId, weekName),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _deleteWeek(context, weekId),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lock Picks', style: TextStyle(fontSize: 18)),
                          Switch(value: isLocked, onChanged: (value) => _toggleLock(weekId, isLocked)),
                        ],
                      ),
                      const Divider(height: 20),
                      const Text('Matches:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      if (games.isEmpty) const Text('No matches added for this week.'),
                      Column(
                        children: games.map((game) {
                          final gameData = game as Map<String, dynamic>;
                          return ListTile(
                            title: Text('${gameData['team1Name']} vs ${gameData['team2Name']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeGame(weekId, gameData),
                            ),
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Match to this Week'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddMatchScreen(weekId: weekId))),
                        ),
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