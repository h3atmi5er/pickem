// lib/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_match_screen.dart'; // Import the new screen

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _toggleLock(bool isCurrentlyLocked) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc('current_week')
        .update({'isLocked': !isCurrentlyLocked});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Controls')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc('current_week')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isLocked = data['isLocked'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week: ${data['weekName'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lock Picks', style: TextStyle(fontSize: 18)),
                    Switch(
                      value: isLocked,
                      onChanged: (value) => _toggleLock(isLocked),
                    ),
                  ],
                ),
                Text(
                  isLocked ? 'Picks are currently LOCKED' : 'Picks are currently OPEN',
                  style: TextStyle(fontSize: 16, color: isLocked ? Colors.red : Colors.green),
                ),
                const Divider(height: 40),

                // --- NEW BUTTON ---
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Match'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddMatchScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}