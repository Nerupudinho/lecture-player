class VideoModel {
  final int? id;
  final int categoryId;
  final String title;
  final String url;
  final int position;

  const VideoModel({
    this.id,
    required this.categoryId,
    required this.title,
    required this.url,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'title': title,
        'url': url,
        'position': position,
      };

  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int,
        title: map['title'] as String,
        url: map['url'] as String,
        position: map['position'] as int,
      );
}
