import '../data/models/video_model.dart';

class ShuffleService {
  final List<VideoModel> _queue = [];
  int _currentIndex = 0;

  VideoModel? nextRandom(List<VideoModel> videos) {
    if (videos.isEmpty) return null;
    if (_queue.isEmpty ||
        _currentIndex >= _queue.length ||
        !_sameSet(videos)) {
      _queue
        ..clear()
        ..addAll(videos)
        ..shuffle();
      _currentIndex = 0;
    }
    return _queue[_currentIndex++];
  }

  void reset() {
    _queue.clear();
    _currentIndex = 0;
  }

  // Check if the provided list matches the current queue's content
  bool _sameSet(List<VideoModel> videos) {
    if (_queue.length != videos.length) return false;
    final queueIds = _queue.map((v) => v.id).toSet();
    return videos.every((v) => queueIds.contains(v.id));
  }
}
