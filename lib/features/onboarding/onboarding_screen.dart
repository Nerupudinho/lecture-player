import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/starter_catalog.dart';
import '../agent/agent_setup_screen.dart';
import '../home/home_provider.dart';

/// First launch: pick topics, get a list to watch immediately. Setting up an
/// agent comes later, after the user has seen the app work.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _picked = <StarterTopic>{};
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    // Keep catalog order so the list is stable whatever order chips were tapped.
    final topics =
        StarterCatalog.topics.where((t) => _picked.contains(t)).toList();
    await ref.read(refreshStateProvider.notifier).useStarters(topics);
    // listSourceProvider now resolves to a starter source; the root swaps
    // this screen for the home tabs.
    if (mounted) setState(() => _busy = false);
  }

  void _haveLink() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const AgentSetupScreen(startAtConnect: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What do you want to learn?',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Pick one or more. You get a hand-picked list of talks right '
                'away. No feed, no algorithm.',
                style: TextStyle(color: Colors.grey.shade400, height: 1.4),
              ),
              const SizedBox(height: 28),
              for (final t in StarterCatalog.topics) ...[
                _TopicTile(
                  topic: t,
                  selected: _picked.contains(t),
                  onTap: () => setState(() =>
                      _picked.contains(t) ? _picked.remove(t) : _picked.add(t)),
                ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _picked.isEmpty || _busy ? null : _start,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Start watching'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _haveLink,
                  child: const Text('I already have a playlist link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final StarterTopic topic;
  final bool selected;
  final VoidCallback onTap;

  const _TopicTile(
      {required this.topic, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(topic.blurb,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? scheme.primary : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
