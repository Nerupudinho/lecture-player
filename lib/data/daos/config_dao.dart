import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class ConfigDao {
  Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> get(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('config',
        columns: ['value'], where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }
}
