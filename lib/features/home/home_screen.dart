import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category_model.dart';
import '../../shared/shuffle_service.dart';
import '../category/category_screen.dart';
import '../player/player_screen.dart';
import 'home_provider.dart';

final _shuffleServiceProvider = Provider((_) => ShuffleService());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allVideosAsync = ref.watch(allVideosProvider);
    final refreshState = ref.watch(refreshStateProvider);

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
                    const Icon(Icons.error_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refreshState.error.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
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
                onPressed: allVideosAsync.valueOrNull?.isEmpty ?? true
                    ? null
                    : () {
                        final videos = allVideosAsync.value!;
                        final shuffler = ref.read(_shuffleServiceProvider);
                        final video = shuffler.nextRandom(videos);
                        if (video != null) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PlayerScreen(
                                      video: video,
                                      categoryVideos: videos,
                                      shuffleService: shuffler)));
                        }
                      },
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle All'),
              ),
            ),
          ),
          // Category list
          Expanded(
            child: categoriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (_, i) =>
                      _CategoryCard(category: categories[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync =
        ref.watch(videosForCategoryProvider(category.id!));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: videosAsync.when(
          data: (v) => Text('${v.length} video${v.length == 1 ? '' : 's'}'),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Error'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline,
                size: 72, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No lectures yet',
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
      ),
    );
  }
}
