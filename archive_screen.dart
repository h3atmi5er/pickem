// lib/archive_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'archive_detail_screen.dart'; // We'll create this next

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Weeks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('archives').orderBy('archivedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final archiveDocs = snapshot.data!.docs;

          if (archiveDocs.isEmpty) {
            return const Center(child: Text('No weeks have been archived yet.'));
          }

          return ListView.builder(
            itemCount: archiveDocs.length,
            itemBuilder: (context, index) {
              final doc = archiveDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final weekName = data['weekName'] ?? 'Unnamed Week';
              final timestamp = data['archivedAt'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat.yMMMd().format(timestamp.toDate())
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(weekName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Archived on: $date'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ArchiveDetailScreen(archiveId: doc.id),
                  )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}