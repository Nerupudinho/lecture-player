import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';

class LecturePlayerApp extends StatefulWidget {
  const LecturePlayerApp({super.key});

  @override
  State<LecturePlayerApp> createState() => _LecturePlayerAppState();
}

class _LecturePlayerAppState extends State<LecturePlayerApp> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
