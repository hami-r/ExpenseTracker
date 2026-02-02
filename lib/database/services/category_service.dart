import 'package:sqflite/sqflite.dart';
import '../../models/category.dart';
import '../database_helper.dart';

class CategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all categories for a user
  Future<List<Category>> getAllCategories(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'display_order ASC, name ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // Get category by ID
  Future<Category?> getCategoryById(int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // Create new category
  Future<int> createCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.categoryId],
    );
  }

  // Deactivate category (soft delete)
  Future<void> deactivateCategory(int categoryId) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }
}
