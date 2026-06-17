class VideoModel {
  final int? id;
  final String title;
  final String url;
  final int position;

  const VideoModel({
    this.id,
    required this.title,
    required this.url,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'position': position,
      };

  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel(
        id: map['id'] as int?,
        title: map['title'] as String,
        url: map['url'] as String,
        position: map['position'] as int,
      );
}
