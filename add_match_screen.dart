// lib/add_match_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1NameController = TextEditingController();
  final _team1ColorController = TextEditingController();
  final _team2NameController = TextEditingController();
  final _team2ColorController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final matchesDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc('current_week')
          .get();
      
      int nextGameId = 1;
      if (matchesDoc.exists && matchesDoc.data()!.containsKey('games')) {
        final games = List<Map<String, dynamic>>.from(matchesDoc.data()!['games']);
        nextGameId = games.length + 1;
      }

      final newGame = {
        'gameId': 'game$nextGameId',
        'team1Name': _team1NameController.text.trim(),
        'team1Color': _team1ColorController.text.trim(),
        'team2Name': _team2NameController.text.trim(),
        'team2Color': _team2ColorController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('matches')
          .doc('current_week')
          .update({
        'games': FieldValue.arrayUnion([newGame])
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add match: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a New Match')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _team1NameController,
                decoration: const InputDecoration(labelText: 'Team 1 Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _team1ColorController,
                decoration: const InputDecoration(labelText: 'Team 1 Hex Color (e.g., F44336)'),
                validator: (value) => value!.isEmpty ? 'Please enter a hex color' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _team2NameController,
                decoration: const InputDecoration(labelText: 'Team 2 Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _team2ColorController,
                decoration: const InputDecoration(labelText: 'Team 2 Hex Color (e.g., 2196F3)'),
                validator: (value) => value!.isEmpty ? 'Please enter a hex color' : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addMatch,
                      child: const Text('Add Match'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}