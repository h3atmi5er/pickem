// lib/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // Function to toggle the lock state in Firestore
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
      // StreamBuilder will listen to changes in your 'matches' document
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
                const SizedBox(height: 10),
                Text(
                  isLocked
                      ? 'Picks are currently LOCKED'
                      : 'Picks are currently OPEN',
                  style: TextStyle(
                      fontSize: 16,
                      color: isLocked ? Colors.red : Colors.green),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}