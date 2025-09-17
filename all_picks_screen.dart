// lib/all_picks_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllPicksScreen extends StatefulWidget {
  const AllPicksScreen({super.key});

  @override
  State<AllPicksScreen> createState() => _AllPicksScreenState();
}

class _AllPicksScreenState extends State<AllPicksScreen> {
  // State variables for week selection
  List<DropdownMenuItem<String>> _weekMenuItems = [];
  String? _selectedWeekId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  // Fetches all available weeks from Firestore to populate the dropdown
  Future<void> _loadAvailableWeeks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('matches').get();
      if (snapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final weeks = snapshot.docs.map((doc) {
        final weekName = (doc.data())['weekName'] ?? 'Unnamed Week';
        return DropdownMenuItem<String>(
          value: doc.id, // e.g., 'week_1'
          child: Text(weekName),
        );
      }).toList();

      setState(() {
        _weekMenuItems = weeks;
        _selectedWeekId = weeks.first.value; // Select the first week by default
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Everyone's Picks"),
        actions: [
          // Dropdown menu to select the week
          if (_weekMenuItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: _selectedWeekId,
                items: _weekMenuItems,
                onChanged: (newWeekId) {
                  if (newWeekId != null) {
                    setState(() => _selectedWeekId = newWeekId);
                  }
                },
                // --- UI CHANGE: Black background for the dropdown menu ---
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: Container(), // Hides the default underline
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedWeekId == null
              ? const Center(child: Text('No weeks available to view.'))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('picks').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No one has made any picks yet.'));
                    }

                    final picks = snapshot.data!.docs;
                    
                    return ListView.builder(
                      itemCount: picks.length,
                      itemBuilder: (context, index) {
                        final pickData = picks[index].data() as Map<String, dynamic>;
                        final displayName = pickData['displayName'] ?? 'Unknown User';
                        
                        // Get the map of picks for the selected week
                        final weekPicksMap = pickData[_selectedWeekId] as Map<String, dynamic>?;

                        List<Widget> picksTextWidgets = [];
                        if (weekPicksMap != null) {
                          // Sort the game IDs so they appear in order (game1, game2, etc.)
                          var sortedKeys = weekPicksMap.keys.toList()..sort();
                          for (var gameId in sortedKeys) {
                             final teamPicked = weekPicksMap[gameId];
                             final gameNumber = gameId.replaceAll('_pick', '').replaceAll('game', '');
                             picksTextWidgets.add(
                               Text('Game $gameNumber: $teamPicked')
                             );
                          }
                        }

                        if (picksTextWidgets.isEmpty) {
                           picksTextWidgets.add(const Text('No picks made for this week.'));
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: picksTextWidgets,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}