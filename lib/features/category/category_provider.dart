import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/video_model.dart';
import '../home/home_provider.dart';

final categoryVideosProvider =
    FutureProvider.family<List<VideoModel>, int>((ref, categoryId) async {
  return ref.read(videoDaoProvider).getByCategory(categoryId);
});
