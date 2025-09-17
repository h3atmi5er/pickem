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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Weeks')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('matches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final weekDocs = snapshot.data!.docs;
          if (weekDocs.isEmpty) {
            return const Center(child: Text('No weeks found. Add one in Firestore.'));
          }

          return ListView.builder(
            itemCount: weekDocs.length,
            itemBuilder: (context, index) {
              final weekDoc = weekDocs[index];
              final data = weekDoc.data() as Map<String, dynamic>;
              final weekId = weekDoc.id;
              final bool isLocked = data['isLocked'] ?? false;
              final weekName = data['weekName'] ?? 'Unnamed Week';

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lock Picks', style: TextStyle(fontSize: 18)),
                          Switch(
                            value: isLocked,
                            onChanged: (value) => _toggleLock(weekId, isLocked),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Match to this Week'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddMatchScreen(weekId: weekId),
                              ),
                            );
                          },
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