// lib/add_match_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({super.key});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  // A key to identify and validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers to read the text from the input fields
  final _team1NameController = TextEditingController();
  final _team1ColorController = TextEditingController();
  final _team2NameController = TextEditingController();
  final _team2ColorController = TextEditingController();
  bool _isLoading = false;

  // The function that handles saving the match to Firestore
  Future<void> _addMatch() async {
    // First, validate the form to make sure all fields are filled out
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get the current list of games to figure out the ID for the new game
      final matchesDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc('current_week')
          .get();
      
      int nextGameId = 1;
      if (matchesDoc.exists && matchesDoc.data()!.containsKey('games')) {
        final games = List<Map<String, dynamic>>.from(matchesDoc.data()!['games']);
        nextGameId = games.length + 1; // If there are 2 games, this will be game3
      }

      // Create a map with the new game's data
      final newGame = {
        'gameId': 'game$nextGameId',
        'team1Name': _team1NameController.text.trim(),
        'team1Color': _team1ColorController.text.trim(),
        'team2Name': _team2NameController.text.trim(),
        'team2Color': _team2ColorController.text.trim(),
      };

      // Use FieldValue.arrayUnion to add the new game to the 'games' array in Firestore
      await FirebaseFirestore.instance
          .collection('matches')
          .doc('current_week')
          .update({
        'games': FieldValue.arrayUnion([newGame])
      });
      
      // If successful, show a confirmation and go back to the previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      // If something goes wrong, show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add match: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Make sure to stop the loading indicator
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
              // Form fields for each piece of information
              TextFormField(
                controller: _team1NameController,
                decoration: const InputDecoration(labelText: 'Team 1 Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _team1ColorController,
                decoration: const InputDecoration(labelText: 'Team 1 Hex Color (e.g., F4