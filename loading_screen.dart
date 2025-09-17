// lib/loading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'nfl_teams.dart'; // We need this for the logo asset paths

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final ScrollController _scrollController;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // After the first frame is rendered, start the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    // A timer that fires every 3 seconds to scroll the list
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // If we are at the end, jump back to the beginning
      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        // Otherwise, smoothly animate to the end
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(seconds: 20), // Adjust duration for scroll speed
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Always cancel timers
    _scrollController.dispose(); // Always dispose controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the list of team objects from your nfl_teams.dart file
    final teams = nflTeamsMap.values.toList();

    return Scaffold(
      backgroundColor: Colors.black, // A dark background looks nice
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Loading App...',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 100, // The height of our scrolling logo container
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                // We build the list twice to ensure continuous scrolling
                itemCount: teams.length * 2, 
                itemBuilder: (context, index) {
                  // Use the modulo operator to loop through the teams
                  final team = teams[index % teams.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.asset(
                      team.logoAssetPath,
                      height: 80,
                      width: 80,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}