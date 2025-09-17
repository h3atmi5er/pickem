// lib/all_picks_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllPicksScreen extends StatelessWidget {
  const AllPicksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Everyone's Picks")),
      // StreamBuilder listens to the entire 'picks' collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('picks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final picks = snapshot.data!.docs;

          if (picks.isEmpty) {
            return const Center(child: Text('No one has made any picks yet.'));
          }

          // A ListView to display the data
          return ListView.builder(
            itemCount: picks.length,
            itemBuilder: (context, index) {
              final pickData = picks[index].data() as Map<String, dynamic>;
              // Assumes picks are stored under a 'current_week' map
              final game1Pick = pickData['current_week']?['game1_pick'] ?? 'No Pick';
              final displayName = pickData['displayName'] ?? 'Unknown User';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Game 1 Pick: $game1Pick'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}