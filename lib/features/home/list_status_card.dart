import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/video_model.dart';
import '../../shared/freshness.dart';
import '../agent/agent_setup_screen.dart';
import 'home_provider.dart';

/// The line above the list that says where it comes from and whether it is
/// alive:
///  - starter list  -> invites the user to let their agent take over
///  - own list      -> "Last updated 2 days ago · 5 new", or a nudge when the
///                     agent seems to have stopped
class ListStatusCard extends ConsumerWidget {
  final List<VideoModel> videos;
  const ListStatusCard({super.key, required this.videos});

  void _openSetup(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AgentSetupScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(listSourceProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(fontSize: 13, color: Colors.grey.shade400);

    if (source is StarterSource) {
      final names = source.topics.map((t) => t.label).join(', ');
      return _Card(
        color: scheme.primaryContainer.withAlpha(90),
        children: [
          Text('Starter list · $names', style: muted),
          const SizedBox(height: 6),
          const Text('Make it yours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Let your AI agent build your list and add new talks weekly.',
              style: muted),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: () => _openSetup(context),
            child: const Text('Connect my agent'),
          ),
        ],
      );
    }

    if (source is OwnSource && videos.isNotEmpty) {
      final f = Freshness.of(videos);
      if (!f.hasDates) {
        return _Card(children: [
          Text('Your list · ${videos.length} items', style: muted),
        ]);
      }
      final summary = 'Your list · ${videos.length} items · '
          'updated ${f.lastAddedLabel}'
          '${f.newCount > 0 ? ' · ${f.newCount} new' : ''}';
      if (!f.isStale) return _Card(children: [Text(summary, style: muted)]);
      return _Card(
        color: Colors.orange.shade900.withAlpha(45),
        children: [
          Text(summary, style: muted),
          const SizedBox(height: 6),
          Text(
            "Nothing new in ${f.daysSinceLastAdded} days. Your agent may have "
            'stopped its weekly refresh.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _openSetup(context),
            child: const Text('Re-share the skill'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final Color? color;
  const _Card({required this.children, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
