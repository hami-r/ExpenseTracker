import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/ai_history.dart';

class AIHistoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const int _maxEntries = 50;

  Future<int> saveEntry(AIHistory history) async {
    final db = await _dbHelper.database;

    // 1. Insert the new entry
    final id = await db.insert('ai_history', history.toMap());

    // 2. Auto-cull older entries per profile to keep 50
    await _cullHistory(db, history.profileId);

    return id;
  }

  Future<void> _cullHistory(Database db, int profileId) async {
    // Keep only the latest _maxEntries for this profile
    await db.execute(
      '''
      DELETE FROM ai_history 
      WHERE profile_id = ? 
      AND history_id NOT IN (
        SELECT history_id 
        FROM ai_history 
        WHERE profile_id = ? 
        ORDER BY timestamp DESC, history_id DESC 
        LIMIT ?
      )
    ''',
      [profileId, profileId, _maxEntries],
    );
  }

  Future<List<AIHistory>> getHistory(int profileId, {int limit = 20}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_history',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'timestamp DESC, history_id DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => AIHistory.fromMap(maps[i]));
  }

  Future<void> clearHistory(int profileId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'ai_history',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }
}
