import 'package:sqflite/sqflite.dart';
import '../../models/reimbursement.dart';
import '../../models/reimbursement_payment.dart';
import '../database_helper.dart';

class ReimbursementService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get active reimbursements
  Future<List<Reimbursement>> getActiveReimbursements(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reimbursements',
      where: 'user_id = ? AND status = ?',
      whereArgs: [
        userId,
        'pending',
      ], // Assuming 'pending' is what we want for active
      orderBy: 'expected_date ASC',
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
  Future<int> createReimbursement(Reimbursement reimbursement) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'reimbursements',
      reimbursement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update reimbursement
  Future<void> updateReimbursement(Reimbursement reimbursement) async {
    final db = await _dbHelper.database;
    await db.update(
      'reimbursements',
      reimbursement.toMap(),
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursement.reimbursementId],
    );
  }

  // Delete reimbursement
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
    await db.update(
      'reimbursements',
      {
        'total_reimbursed': totalReimbursed,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'reimbursement_id = ?',
      whereArgs: [reimbursementId],
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
