import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllPicksScreen extends StatefulWidget {
  const AllPicksScreen({super.key});

  @override
  State<AllPicksScreen> createState() => _AllPicksScreenState();
}

class _AllPicksScreenState extends State<AllPicksScreen> {
  List<DropdownMenuItem<String>> _weekMenuItems = [];
  String? _selectedWeekId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableWeeks();
  }

  Future<void> _loadAvailableWeeks() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('matches').get();
      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final weeks = snapshot.docs.map((doc) {
        final weekName = (doc.data())['weekName'] ?? 'Unnamed Week';
        return DropdownMenuItem<String>(value: doc.id, child: Text(weekName));
      }).toList();

      if (mounted) {
        setState(() {
          _weekMenuItems = weeks;
          _selectedWeekId = weeks.first.value;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading weeks: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Everyone's Picks"),
        actions: [
          if (_weekMenuItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: _selectedWeekId,
                items: _weekMenuItems,
                onChanged: (newWeekId) {
                  if (newWeekId != null) setState(() => _selectedWeekId = newWeekId);
                },
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: Container(),
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
                  stream: FirebaseFirestore.instance
                      .collection('picks')
                      .where(_selectedWeekId!, isNotEqualTo: null)
                      .snapshots(),
                  builder: (context, picksSnapshot) {
                    if (picksSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!picksSnapshot.hasData || picksSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No one has made any picks yet.'));
                    }

                    final picks = picksSnapshot.data!.docs;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('matches').doc(_selectedWeekId!).snapshots(),
                      builder: (context, matchSnapshot) {
                        if (!matchSnapshot.hasData || !matchSnapshot.data!.exists) {
                          return const Center(child: Text('This week has no matches scheduled.'));
                        }

                        final matchData = matchSnapshot.data!.data() as Map<String, dynamic>;
                        final List<dynamic> games = matchData['games'] ?? [];

                        if (games.isEmpty) {
                          return const Center(child: Text('No matches have been added for this week yet.'));
                        }

                        return ListView.builder(
                          itemCount: picks.length,
                          itemBuilder: (context, index) {
                            final pickData = picks[index].data() as Map<String, dynamic>;
                            final displayName = pickData['displayName'] ?? 'Unknown User';
                            final weekPicksMap = pickData[_selectedWeekId] as Map<String, dynamic>? ?? {};

                            List<Widget> picksTextWidgets = games.map((game) {
                              final gameData = game as Map<String, dynamic>;
                              final gameId = gameData['gameId'];
                              final userPick = weekPicksMap[gameId] ?? 'No Pick';
                              final gameNumber = gameId.replaceAll('game', '');
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('Game $gameNumber: $userPick'),
                              );
                            }).toList();
                            
                            if (picksTextWidgets.isEmpty) {
                              picksTextWidgets.add(const Text('No matches scheduled for this week.'));
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
                    );
                  },
                ),
    );
  }
}