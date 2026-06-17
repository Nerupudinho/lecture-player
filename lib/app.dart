import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';

class LecturePlayerApp extends ConsumerStatefulWidget {
  const LecturePlayerApp({super.key});

  @override
  ConsumerState<LecturePlayerApp> createState() => _LecturePlayerAppState();
}

class _LecturePlayerAppState extends ConsumerState<LecturePlayerApp> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-sync from the sheet once on launch. Runs silently; any error
    // surfaces in the home screen's banner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(refreshStateProvider.notifier).refresh();
    });
  }

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
