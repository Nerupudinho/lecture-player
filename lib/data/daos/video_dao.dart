import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/video_model.dart';

class VideoDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insert(VideoModel video) async {
    final db = await _db;
    return db.insert('videos', video.toMap());
  }

  Future<List<VideoModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('videos', orderBy: 'position ASC');
    return rows.map(VideoModel.fromMap).toList();
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('videos');
  }
}
