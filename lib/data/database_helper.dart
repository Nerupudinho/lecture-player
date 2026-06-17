import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lecture_player.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createVideos(db);
    await db.execute('''
      CREATE TABLE config (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // v1 had categories + videos.category_id. v2 drops categories entirely; the
  // app is now a flat list. Data is re-synced from the sheet on next open, so
  // dropping the videos table is safe.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS videos');
      await _createVideos(db);
    }
  }

  Future<void> _createVideos(Database db) async {
    await db.execute('''
      CREATE TABLE videos (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        title    TEXT NOT NULL,
        url      TEXT NOT NULL,
        position INTEGER NOT NULL
      )
    ''');
  }
}
