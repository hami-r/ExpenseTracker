import '../../models/user.dart';
import '../database_helper.dart';

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get current user (assumes single user for now)
  Future<User?> getCurrentUser() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Get user by ID
  Future<User?> getUserById(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Update user
  Future<void> updateUser(User user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // Update user theme
  Future<void> updateUserTheme(
    int userId,
    String themeColor,
    String themePreference,
  ) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {
        'theme_color': themeColor,
        'theme_preference': themePreference,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
