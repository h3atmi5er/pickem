// lib/add_match_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'nfl_teams.dart'; // Import the new teams list

class AddMatchScreen extends StatefulWidget {
  final String weekId;
  const AddMatchScreen({super.key, required this.weekId});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTeam1;
  String? _selectedTeam2;
  bool _isLoading = false;

  Future<void> _addMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeam1 == _selectedTeam2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two different teams.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final matchesDoc = await FirebaseFirestore.instance.collection('matches').doc(widget.weekId).get();
      int nextGameId = 1;
      if (matchesDoc.exists && matchesDoc.data()!.containsKey('games')) {
        nextGameId = (matchesDoc.data()!['games'] as List).length + 1;
      }
      final newGame = {'gameId': 'game$nextGameId', 'team1Name': _selectedTeam1, 'team2Name': _selectedTeam2};
      await FirebaseFirestore.instance.collection('matches').doc(widget.weekId).update({
        'games': FieldValue.arrayUnion([newGame])
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match added successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add match: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Match to ${widget.weekId.replaceAll('_', ' ')}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- FIX: Use the keys from the new nflTeamsMap ---
              DropdownButtonFormField<String>(
                value: _selectedTeam1,
                decoration: const InputDecoration(labelText: 'Team 1'),
                items: nflTeamsMap.keys.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
                onChanged: (value) => setState(() => _selectedTeam1 = value),
                validator: (value) => value == null ? 'Please select a team' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedTeam2,
                decoration: const InputDecoration(labelText: 'Team 2'),
                items: nflTeamsMap.keys.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
                onChanged: (value) => setState(() => _selectedTeam2 = value),
                validator: (value) => value == null ? 'Please select a team' : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _addMatch, child: const Text('Add Match')),
            ],
          ),
        ),
      ),
    );
  }
}