import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/video_model.dart';
import '../../shared/shuffle_service.dart';
import '../player/player_screen.dart';
import 'home_provider.dart';

final _shuffleServiceProvider = Provider((_) => ShuffleService());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _play(
    BuildContext context,
    WidgetRef ref,
    VideoModel video,
    List<VideoModel> playlist,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          video: video,
          playlist: playlist,
          shuffleService: ref.read(_shuffleServiceProvider),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allVideosAsync = ref.watch(allVideosProvider);
    final refreshState = ref.watch(refreshStateProvider);
    final videos = allVideosAsync.valueOrNull ?? const <VideoModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Player'),
        actions: [
          if (refreshState.isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Refresh error banner
          if (refreshState.hasError)
            Material(
              color: Colors.red.shade900,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refreshState.error.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Shuffle All button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: videos.isEmpty
                    ? null
                    : () {
                        final shuffler = ref.read(_shuffleServiceProvider);
                        final video = shuffler.nextRandom(videos);
                        if (video != null) _play(context, ref, video, videos);
                      },
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle All'),
              ),
            ),
          ),
          // Flat lecture list (titles only)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(refreshStateProvider.notifier).refresh(),
              child: allVideosAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('Error: $e',
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
                data: (videos) {
                  if (videos.isEmpty) {
                    return ListView(
                      children: const [_EmptyState()],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: videos.length,
                    itemBuilder: (_, i) {
                      final video = videos[i];
                      return ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text(video.title),
                        onTap: () => _play(context, ref, video, videos),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Icon(Icons.play_circle_outline,
              size: 72, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No lectures yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Settings, paste your playlist URL, and tap Refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
