import 'package:sqflite/sqflite.dart';
import '../../models/reimbursement.dart';
import '../../models/reimbursement_payment.dart';
import '../database_helper.dart';

class ReimbursementService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get active reimbursements
  Future<List<Reimbursement>> getActiveReimbursements(
    int userId, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, 'active', 'pending', profileId]
        : [userId, 'active', 'pending'];
    final List<Map<String, dynamic>> maps = await db.query(
      'reimbursements',
      where:
          'user_id = ? AND status IN (?, ?) AND is_deleted = 0$profileClause',
      whereArgs: args,
      orderBy: 'expected_date ASC',
    );
    return List.generate(maps.length, (i) => Reimbursement.fromMap(maps[i]));
  }

  // Get completed reimbursements
  Future<List<Reimbursement>> getCompletedReimbursements(
    int userId, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, 'completed', profileId]
        : [userId, 'completed'];
    final List<Map<String, dynamic>> maps = await db.query(
      'reimbursements',
      where: 'user_id = ? AND status = ? AND is_deleted = 0$profileClause',
      whereArgs: args,
      orderBy: 'updated_at DESC, expected_date DESC',
    );
    return List.generate(maps.length, (i) => Reimbursement.fromMap(maps[i]));
  }

  // Get reimbursement by ID
  Future<Reimbursement?> getReimbursementById(int reimbursementId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reimbursements',
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursementId],
    );
    if (maps.isEmpty) return null;
    return Reimbursement.fromMap(maps.first);
  }

  // Create new reimbursement
  Future<int> createReimbursement(
    Reimbursement reimbursement, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final map = reimbursement.toMap();
    if (profileId != null) map['profile_id'] = profileId;
    return await db.insert(
      'reimbursements',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update reimbursement
  Future<void> updateReimbursement(
    Reimbursement reimbursement, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final map = reimbursement.toMap();
    if (profileId != null) map['profile_id'] = profileId;
    await db.update(
      'reimbursements',
      map,
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursement.reimbursementId],
    );
  }

  // Soft Delete a reimbursement
  Future<void> softDeleteReimbursement(int reimbursementId) async {
    final db = await _dbHelper.database;
    await db.update(
      'reimbursements',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursementId],
    );
  }

  // Hard Delete a reimbursement
  Future<void> deleteReimbursement(int reimbursementId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'reimbursements',
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursementId],
    );
  }

  // Update total reimbursed
  Future<void> updateReimbursementTotalReimbursed(
    int reimbursementId,
    double totalReimbursed,
  ) async {
    final db = await _dbHelper.database;
    final clampedTotalReimbursed = totalReimbursed < 0 ? 0.0 : totalReimbursed;
    await db.rawUpdate(
      '''
      UPDATE reimbursements
      SET
        total_reimbursed = ?,
        status = CASE
          WHEN ? >= amount THEN 'completed'
          ELSE 'pending'
        END,
        updated_at = ?
      WHERE reimbursement_id = ?
      ''',
      [
        clampedTotalReimbursed,
        clampedTotalReimbursed,
        DateTime.now().toIso8601String(),
        reimbursementId,
      ],
    );
  }

  // Get reimbursement payments
  Future<List<ReimbursementPayment>> getReimbursementPayments(
    int reimbursementId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reimbursement_payments',
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursementId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(
      maps.length,
      (i) => ReimbursementPayment.fromMap(maps[i]),
    );
  }

  // Create reimbursement payment
  Future<int> createReimbursementPayment(ReimbursementPayment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'reimbursement_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
