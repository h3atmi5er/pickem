// lib/admin_screen.dart
import 'package:flutter/material.dart';
import 'manage_weeks_screen.dart'; // New screen for week management
import 'set_active_week_screen.dart'; // New screen for setting the active week
import 'archive_screen.dart'; // Existing screen for archives

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _AdminNavigationCard(
            title: 'Manage Weeks & Matches',
            subtitle: 'Create, edit, and delete upcoming weeks and their matches.',
            icon: Icons.edit_calendar,
            destination: ManageWeeksScreen(),
          ),
          _AdminNavigationCard(
            title: 'Set Active Week',
            subtitle: 'Choose which week is currently displayed for users.',
            icon: Icons.star,
            destination: SetActiveWeekScreen(),
          ),
          _AdminNavigationCard(
            title: 'View Archived Weeks',
            subtitle: 'Manage scores and details for completed weeks.',
            icon: Icons.archive,
            destination: ArchiveScreen(),
          ),
          // You can easily add more admin features here in the future
        ],
      ),
    );
  }
}

// A reusable card widget for navigation to keep the code clean
class _AdminNavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget destination;

  const _AdminNavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}