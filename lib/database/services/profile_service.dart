import '../database_helper.dart';
import '../../models/profile.dart';

class ProfileService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Returns all profiles for the user with currency details joined.
  Future<List<Profile>> getAllProfiles(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, c.currency_code, c.symbol, c.currency_name
      FROM profiles p
      INNER JOIN currencies c ON p.currency_id = c.currency_id
      WHERE p.user_id = ?
      ORDER BY p.is_active DESC, p.created_at ASC
    ''',
      [userId],
    );
    return rows.map((r) => Profile.fromMap(r)).toList();
  }

  /// Returns the currently active profile for the user (or null).
  Future<Profile?> getActiveProfile(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, c.currency_code, c.symbol, c.currency_name
      FROM profiles p
      INNER JOIN currencies c ON p.currency_id = c.currency_id
      WHERE p.user_id = ? AND p.is_active = 1
      LIMIT 1
    ''',
      [userId],
    );
    if (rows.isEmpty) return null;
    return Profile.fromMap(rows.first);
  }

  /// Creates a new profile and returns its ID.
  Future<int> createProfile(Profile profile) async {
    final db = await _dbHelper.database;
    return await db.insert('profiles', profile.toMap());
  }

  /// Updates an existing profile's name, currency, and country.
  Future<void> updateProfile(Profile profile) async {
    final db = await _dbHelper.database;
    await db.update(
      'profiles',
      {
        'name': profile.name,
        'currency_id': profile.currencyId,
        'country_code': profile.countryCode,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'profile_id = ?',
      whereArgs: [profile.profileId],
    );
  }

  /// Sets the given profile as active; deactivates all others for the user.
  Future<void> setActiveProfile(int profileId, int userId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Deactivate all
      await txn.update(
        'profiles',
        {'is_active': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      // Activate selected
      await txn.update(
        'profiles',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
    });
  }

  /// Hard deletes a profile. Caller should guard against deleting the active one.
  Future<void> deleteProfile(int profileId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'profiles',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  /// Returns all currencies available for selection.
  Future<List<Map<String, dynamic>>> getAllCurrencies() async {
    final db = await _dbHelper.database;
    return await db.query(
      'currencies',
      where: 'is_active = 1',
      orderBy: 'currency_name ASC',
    );
  }
}
