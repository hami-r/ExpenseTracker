import 'package:sqflite/sqflite.dart';
import '../../models/category.dart';
import '../database_helper.dart';

class CategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> _getNextDisplayOrder(DatabaseExecutor db, int userId) async {
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(display_order), 0) + 1 AS next_order FROM categories WHERE user_id = ?',
      [userId],
    );
    return (result.first['next_order'] as int?) ?? 1;
  }

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
    final map = category.toMap();
    if ((map['display_order'] as int? ?? 0) <= 0) {
      map['display_order'] = await _getNextDisplayOrder(db, category.userId);
    }
    return await db.insert(
      'categories',
      map,
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

  Future<List<Category>> getRecentCategories(
    int userId, {
    int? profileId,
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final splitProfileClause = profileId != null ? ' AND t.profile_id = ?' : '';
    final args = <Object?>[
      userId,
      if (profileId != null) profileId,
      userId,
      if (profileId != null) profileId,
      userId,
      limit,
    ];

    final rows = await db.rawQuery('''
      SELECT c.*
      FROM categories c
      INNER JOIN (
        SELECT usage.category_id, MAX(usage.last_used_at) AS last_used_at
        FROM (
          SELECT
            category_id,
            COALESCE(updated_at, created_at, transaction_date) AS last_used_at
          FROM transactions
          WHERE user_id = ?
            AND category_id IS NOT NULL
            AND parent_transaction_id IS NULL$profileClause

          UNION ALL

          SELECT
            si.category_id,
            COALESCE(t.updated_at, t.created_at, t.transaction_date) AS last_used_at
          FROM split_items si
          INNER JOIN transactions t ON t.transaction_id = si.transaction_id
          WHERE t.user_id = ?
            AND si.category_id IS NOT NULL$splitProfileClause
        ) usage
        GROUP BY usage.category_id
      ) recent ON recent.category_id = c.category_id
      WHERE c.user_id = ?
        AND c.is_active = 1
      ORDER BY recent.last_used_at DESC, c.name ASC
      LIMIT ?
      ''', args);

    return rows.map(Category.fromMap).toList();
  }

  Future<void> updateCategoryOrder(
    int userId,
    List<Category> categories,
  ) async {
    final db = await _dbHelper.database;
    final updatedAt = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var index = 0; index < categories.length; index++) {
        final categoryId = categories[index].categoryId;
        if (categoryId == null) continue;

        batch.update(
          'categories',
          {'display_order': index + 1, 'updated_at': updatedAt},
          where: 'category_id = ? AND user_id = ?',
          whereArgs: [categoryId, userId],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
