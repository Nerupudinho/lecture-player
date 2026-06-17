import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/video_dao.dart';
import '../../data/daos/config_dao.dart';
import '../../data/models/video_model.dart';
import '../../services/fetcher_service.dart';
import '../../services/csv_parser_service.dart';

// --- Providers ---

final videoDaoProvider = Provider((_) => VideoDao());
final configDaoProvider = Provider((_) => ConfigDao());
final fetcherProvider = Provider((_) => FetcherService());
final csvParserProvider = Provider((_) => CsvParserService());

// All videos (flat list for the home screen + shuffle)
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
        state = AsyncValue.error(
            'No source URL configured. Go to Settings.', StackTrace.current);
        return;
      }
      final raw = await _ref.read(fetcherProvider).fetch(url);
      final videos = _ref.read(csvParserProvider).parse(raw);

      final videoDao = _ref.read(videoDaoProvider);
      await videoDao.deleteAll();
      for (final video in videos) {
        await videoDao.insert(video);
      }

      await configDao.set('last_fetched_at', DateTime.now().toIso8601String());

      _ref.invalidate(allVideosProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
