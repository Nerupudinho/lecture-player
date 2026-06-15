import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/category_dao.dart';
import '../../data/daos/video_dao.dart';
import '../../data/daos/config_dao.dart';
import '../../data/models/category_model.dart';
import '../../data/models/video_model.dart';
import '../../services/fetcher_service.dart';
import '../../services/csv_parser_service.dart';

// --- Providers ---

final categoryDaoProvider = Provider((_) => CategoryDao());
final videoDaoProvider = Provider((_) => VideoDao());
final configDaoProvider = Provider((_) => ConfigDao());
final fetcherProvider = Provider((_) => FetcherService());
final csvParserProvider = Provider((_) => CsvParserService());

// Category list for home screen
final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return ref.read(categoryDaoProvider).getAll();
});

// Video count per category
final videosForCategoryProvider =
    FutureProvider.family<List<VideoModel>, int>((ref, categoryId) async {
  return ref.read(videoDaoProvider).getByCategory(categoryId);
});

// All videos (for shuffle all)
final allVideosProvider = FutureProvider<List<VideoModel>>((ref) async {
  return ref.read(videoDaoProvider).getAll();
});

// Refresh state
final refreshStateProvider =
    StateNotifierProvider<RefreshNotifier, AsyncValue<void>>(
        (ref) => RefreshNotifier(ref));

class RefreshNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  RefreshNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final configDao = _ref.read(configDaoProvider);
      final url = await configDao.get('source_url') ?? '';
      if (url.isEmpty) {
        state = AsyncValue.error('No source URL configured. Go to Settings.', StackTrace.current);
        return;
      }
      final raw = await _ref.read(fetcherProvider).fetch(url);
      final parsed = _ref.read(csvParserProvider).parse(raw);

      final categoryDao = _ref.read(categoryDaoProvider);
      final videoDao = _ref.read(videoDaoProvider);

      await videoDao.deleteAll();
      await categoryDao.deleteAll();

      for (final pc in parsed) {
        final id = await categoryDao.insert(pc.category);
        // If insert returned 0 (conflict), get existing id
        final catId = id > 0
            ? id
            : (await categoryDao.getByName(pc.category.name))?.id ?? id;
        for (final video in pc.videos) {
          await videoDao.insert(VideoModel(
            categoryId: catId,
            title: video.title,
            url: video.url,
            position: video.position,
          ));
        }
      }

      final now = DateTime.now().toIso8601String();
      await configDao.set('last_fetched_at', now);

      // Invalidate cached data
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(allVideosProvider);
      _ref.invalidate(videosForCategoryProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
