// lib/set_active_week_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetActiveWeekScreen extends StatelessWidget {
  const SetActiveWeekScreen({super.key});

  Future<void> _setActiveWeek(BuildContext context, String weekId) async {
    await FirebaseFirestore.instance.collection('app_status').doc('status').set({
      'activeWeekId': weekId,
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$weekId is now the active week.'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Active Week'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_status')
            .doc('status')
            .snapshots(),
        builder: (context, statusSnapshot) {
          if (statusSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeWeekId =
              (statusSnapshot.data?.data() as Map<String, dynamic>?)?['activeWeekId'];

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
                return const Center(child: Text('No weeks exist to be set as active.'));
              }

              final weekDocs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: weekDocs.length,
                itemBuilder: (context, index) {
                  final weekDoc = weekDocs[index];
                  final weekId = weekDoc.id;
                  final weekName =
                      (weekDoc.data() as Map<String, dynamic>)['weekName'] ??
                          'Unnamed Week';
                  final bool isActive = weekId == activeWeekId;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading:
                          Icon(isActive ? Icons.star : Icons.star_border),
                      title: Text(weekName),
                      trailing: ElevatedButton(
                        onPressed:
                            isActive ? null : () => _setActiveWeek(context, weekId),
                        child: const Text('Set Active'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}