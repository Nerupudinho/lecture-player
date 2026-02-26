import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/category_model.dart';

class CategoryDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<int> insert(CategoryModel category) async {
    final db = await _db;
    return db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<CategoryModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getByName(String name) async {
    final db = await _db;
    final rows = await db.query('categories',
        where: 'name = ?', whereArgs: [name], limit: 1);
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('categories');
  }
}
