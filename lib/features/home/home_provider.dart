import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/video_dao.dart';
import '../../data/daos/config_dao.dart';
import '../../data/models/video_model.dart';
import '../../services/fetcher_service.dart';
import '../../services/csv_parser_service.dart';
import '../../services/source_link.dart';
import '../../services/starter_catalog.dart';

// --- Config keys ---

const kSourceUrl = 'source_url';
const kStarterTopics = 'starter_topics';
const kLastFetchedAt = 'last_fetched_at';

// --- Providers ---

final videoDaoProvider = Provider((_) => VideoDao());
final configDaoProvider = Provider((_) => ConfigDao());
final fetcherProvider = Provider((_) => FetcherService());
final csvParserProvider = Provider((_) => CsvParserService());

// All videos (flat list for the home screen + shuffle)
final allVideosProvider = FutureProvider<List<VideoModel>>((ref) async {
  return ref.read(videoDaoProvider).getAll();
});

/// Where the list comes from: the user's own link, or bundled starter lists.
sealed class ListSource {
  const ListSource();
}

class NoSource extends ListSource {
  const NoSource();
}

class StarterSource extends ListSource {
  final List<StarterTopic> topics;
  const StarterSource(this.topics);
}

class OwnSource extends ListSource {
  final String url;
  const OwnSource(this.url);
}

final listSourceProvider = FutureProvider<ListSource>((ref) async {
  final config = ref.read(configDaoProvider);
  final url = (await config.get(kSourceUrl) ?? '').trim();
  if (url.isNotEmpty) return OwnSource(url);
  final topics = StarterCatalog.decode(await config.get(kStarterTopics));
  if (topics.isNotEmpty) return StarterSource(topics);
  return const NoSource();
});

// Refresh state
final refreshStateProvider =
    StateNotifierProvider<RefreshNotifier, AsyncValue<void>>(
        (ref) => RefreshNotifier(ref));

class RefreshNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  RefreshNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Reloads the list from its current source and replaces the local cache.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final source = await _ref.refresh(listSourceProvider.future);
      final List<VideoModel> videos;
      if (source is OwnSource) {
        final raw = await _ref
            .read(fetcherProvider)
            .fetch(SourceLink.normalize(source.url));
        videos = _ref.read(csvParserProvider).parse(raw);
      } else if (source is StarterSource) {
        videos = await _loadStarters(source.topics);
      } else {
        state = const AsyncValue.data(null);
        return;
      }
      await _store(videos);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Switches to bundled starter lists (first launch, or "use a starter list").
  Future<void> useStarters(List<StarterTopic> topics) async {
    final config = _ref.read(configDaoProvider);
    await config.set(kStarterTopics, StarterCatalog.encode(topics));
    await config.set(kSourceUrl, '');
    await refresh();
  }

  /// Switches to the user's own list. [videos] were already fetched and
  /// checked by the connect screen, so this stores them without a re-fetch.
  Future<void> useOwnList(String url, List<VideoModel> videos) async {
    await _ref.read(configDaoProvider).set(kSourceUrl, url);
    _ref.invalidate(listSourceProvider);
    await _store(videos);
    state = const AsyncValue.data(null);
  }

  Future<List<VideoModel>> _loadStarters(List<StarterTopic> topics) async {
    // Interleave the chosen topics so Shuffle and the top of the list mix
    // them, rather than showing all of one topic first.
    final parser = _ref.read(csvParserProvider);
    final lists = <List<VideoModel>>[];
    for (final t in topics) {
      lists.add(parser.parse(await rootBundle.loadString(t.assetPath)));
    }
    final merged = <VideoModel>[];
    final seen = <String>{};
    for (var i = 0; lists.any((l) => i < l.length); i++) {
      for (final l in lists) {
        if (i < l.length && seen.add(l[i].url)) merged.add(l[i]);
      }
    }
    return merged;
  }

  Future<void> _store(List<VideoModel> videos) async {
    final videoDao = _ref.read(videoDaoProvider);
    await videoDao.deleteAll();
    var position = 0;
    for (final v in videos) {
      await videoDao.insert(VideoModel(
        title: v.title,
        url: v.url,
        position: position++,
        why: v.why,
        minutes: v.minutes,
        added: v.added,
      ));
    }
    await _ref
        .read(configDaoProvider)
        .set(kLastFetchedAt, DateTime.now().toIso8601String());
    _ref.invalidate(allVideosProvider);
  }
}
