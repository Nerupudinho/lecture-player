import '../data/models/category_model.dart';
import '../data/models/video_model.dart';

class ParsedCategory {
  final CategoryModel category;
  final List<VideoModel> videos;
  ParsedCategory({required this.category, required this.videos});
}

class MdParserService {
  static final _categoryRe = RegExp(r'^## (.+)$');
  static final _videoRe = RegExp(r'^\s*-\s+\[(.+?)\]\((.+?)\)\s*$');

  List<ParsedCategory> parse(String markdown) {
    final result = <ParsedCategory>[];
    ParsedCategory? current;

    for (final line in markdown.split('\n')) {
      final catMatch = _categoryRe.firstMatch(line);
      if (catMatch != null) {
        if (current != null) result.add(current);
        current = ParsedCategory(
          category: CategoryModel(name: catMatch.group(1)!.trim()),
          videos: [],
        );
        continue;
      }
      if (current == null) continue;
      final vidMatch = _videoRe.firstMatch(line);
      if (vidMatch != null) {
        current.videos.add(VideoModel(
          categoryId: 0, // will be set after DB insert
          title: vidMatch.group(1)!.trim(),
          url: vidMatch.group(2)!.trim(),
          position: current.videos.length,
        ));
      }
    }
    if (current != null) result.add(current);
    return result;
  }
}
