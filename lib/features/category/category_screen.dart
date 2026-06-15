import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../data/models/video_model.dart';
import '../../shared/shuffle_service.dart';
import '../player/player_screen.dart';
import '../home/home_provider.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel category;
  const CategoryScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late final ShuffleService _shuffler = ShuffleService();

  void _openPlayer(List<VideoModel> videos, VideoModel startVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          video: startVideo,
          categoryVideos: videos,
          shuffleService: _shuffler,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync =
        ref.watch(videosForCategoryProvider(widget.category.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          videosAsync.when(
            data: (videos) => videos.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Shuffle category',
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {
                      final video = _shuffler.nextRandom(videos);
                      if (video != null) _openPlayer(videos, video);
                    },
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: videosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(child: Text('No videos in this category.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final video = videos[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade900,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(video.title),
                subtitle: Text(
                  video.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: () => _openPlayer(videos, video),
              );
            },
          );
        },
      ),
      floatingActionButton: videosAsync.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () {
                final videos = videosAsync.value!;
                final video = _shuffler.nextRandom(videos);
                if (video != null) _openPlayer(videos, video);
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
            )
          : null,
    );
  }
}
