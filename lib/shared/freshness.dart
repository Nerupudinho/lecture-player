import '../data/models/video_model.dart';

/// How fresh the user's own list is, judged from the `Added` dates the agent
/// writes. This is the only signal the app has that the agent is still running,
/// so it is shown on the home screen.
class Freshness {
  /// An item counts as "new" for this many days after it was added.
  static const newWindowDays = 7;

  /// After this many days with nothing added, the list is "stale": the agent
  /// has probably stopped running and the user is nudged to re-share the skill.
  static const staleAfterDays = 10;

  final DateTime? lastAdded;
  final int newCount;
  final bool hasDates;
  final DateTime now;

  const Freshness._(this.lastAdded, this.newCount, this.hasDates, this.now);

  factory Freshness.of(List<VideoModel> videos, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    DateTime? latest;
    var fresh = 0;
    for (final v in videos) {
      final d = v.added == null ? null : DateTime.tryParse(v.added!);
      if (d == null) continue;
      if (latest == null || d.isAfter(latest)) latest = d;
      if (today.difference(_dateOnly(d)).inDays < newWindowDays) fresh++;
    }
    return Freshness._(latest, fresh, latest != null, today);
  }

  int? get daysSinceLastAdded =>
      lastAdded == null ? null : now.difference(_dateOnly(lastAdded!)).inDays;

  bool get isStale =>
      daysSinceLastAdded != null && daysSinceLastAdded! >= staleAfterDays;

  /// "today", "yesterday", "3 days ago", "5 weeks ago".
  String get lastAddedLabel {
    final d = daysSinceLastAdded;
    if (d == null) return 'unknown';
    if (d <= 0) return 'today';
    if (d == 1) return 'yesterday';
    if (d < 14) return '$d days ago';
    return '${d ~/ 7} weeks ago';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
