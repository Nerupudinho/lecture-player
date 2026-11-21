import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';

/// Root: first-time users (no list yet) see onboarding; everyone else gets
/// the home and settings tabs. Existing installs already have a source URL,
/// so they never see onboarding.
class LecturePlayerApp extends ConsumerWidget {
  const LecturePlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(listSourceProvider);
    return source.when(
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, __) => const _Tabs(),
      data: (s) => s is NoSource ? const OnboardingScreen() : const _Tabs(),
    );
  }
}

class _Tabs extends ConsumerStatefulWidget {
  const _Tabs();

  @override
  ConsumerState<_Tabs> createState() => _TabsState();
}

class _TabsState extends ConsumerState<_Tabs> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Sync once on launch. Runs silently; any error surfaces in the home
    // screen's banner.
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
