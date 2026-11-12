class VideoModel {
  final int? id;
  final String title;
  final String url;
  final int position;

  /// One line from the list's curator (usually the user's agent) saying why
  /// this item is worth watching. Optional `Why` column.
  final String? why;

  /// Runtime in minutes. Optional `Minutes` column.
  final int? minutes;

  /// Date the item was added to the list, `YYYY-MM-DD`. Optional `Added`
  /// column. Drives the "last updated" and "new" signals on the home screen.
  final String? added;

  const VideoModel({
    this.id,
    required this.title,
    required this.url,
    required this.position,
    this.why,
    this.minutes,
    this.added,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'position': position,
        'why': why,
        'minutes': minutes,
        'added': added,
      };

  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        url: map['url'] as String,
        position: map['position'] as int,
        why: map['why'] as String?,
        minutes: map['minutes'] as int?,
        added: map['added'] as String?,
      );
}
