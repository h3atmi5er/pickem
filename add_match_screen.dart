import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';
import 'nfl_teams.dart';

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

  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();

  Future<void> _addMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeam1 == _selectedTeam2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select two different teams.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final matchesRef =
          FirebaseFirestore.instance.collection('matches').doc(widget.weekId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchesRef);

        if (!snapshot.exists) {
          throw Exception("Document does not exist!");
        }

        final games =
            List<Map<String, dynamic>>.from(snapshot.data()!['games'] ?? []);
        final nextGameId = games.length + 1;
        final newGame = {
          'gameId': 'game$nextGameId',
          'team1Name': _selectedTeam1,
          'team2Name': _selectedTeam2,
        };

        transaction.update(matchesRef, {
          'games': FieldValue.arrayUnion([newGame])
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Match added successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add match: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = nflTeamsMap.keys.toList();
    return Scaffold(
      appBar: AppBar(
          title: Text('Add Match to ${widget.weekId.replaceAll('_', ' ')}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SearchField<String>(
                controller: _team1Controller,
                suggestions: teams
                    .map((team) =>
                        SearchFieldListItem<String>(team, child: Text(team)))
                    .toList(),
                onSuggestionTap: (SearchFieldListItem<String> suggestion) {
                  setState(() {
                    _selectedTeam1 = suggestion.searchKey;
                    _team1Controller.text = suggestion.searchKey;
                  });
                  // Manually dismiss the keyboard
                  FocusScope.of(context).unfocus();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a team';
                  }
                  if (!teams.contains(value)) {
                    return 'Please select a valid team';
                  }
                  return null;
                },
                searchInputDecoration: SearchInputDecoration(
                  labelText: 'Team 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SearchField<String>(
                controller: _team2Controller,
                suggestions: teams
                    .map((team) =>
                        SearchFieldListItem<String>(team, child: Text(team)))
                    .toList(),
                onSuggestionTap: (SearchFieldListItem<String> suggestion) {
                  setState(() {
                    _selectedTeam2 = suggestion.searchKey;
                    _team2Controller.text = suggestion.searchKey;
                  });
                   // Manually dismiss the keyboard
                  FocusScope.of(context).unfocus();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a team';
                  }
                  if (!teams.contains(value)) {
                    return 'Please select a valid team';
                  }
                  return null;
                },
                searchInputDecoration: SearchInputDecoration(
                  labelText: 'Team 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _addMatch, child: const Text('Add Match')),
            ],
          ),
        ),
      ),
    );
  }
}