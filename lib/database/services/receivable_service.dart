import 'package:sqflite/sqflite.dart';
import '../../models/receivable.dart';
import '../../models/receivable_payment.dart';
import '../database_helper.dart';

class ReceivableService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get active receivables
  Future<List<Receivable>> getActiveReceivables(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receivables',
      where: 'user_id = ? AND status = ? AND is_deleted = 0',
      whereArgs: [userId, 'active'],
      orderBy: 'expected_date ASC',
    );
    return List.generate(maps.length, (i) => Receivable.fromMap(maps[i]));
  }

  // Get receivable by ID
  Future<Receivable?> getReceivableById(int receivableId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receivables',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
    );
    if (maps.isEmpty) return null;
    return Receivable.fromMap(maps.first);
  }

  // Create new receivable
  Future<int> createReceivable(Receivable receivable) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'receivables',
      receivable.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update receivable
  Future<void> updateReceivable(Receivable receivable) async {
    final db = await _dbHelper.database;
    await db.update(
      'receivables',
      receivable.toMap(),
      where: 'receivable_id = ?',
      whereArgs: [receivable.receivableId],
    );
  }

  // Soft Delete a receivable
  Future<void> softDeleteReceivable(int receivableId) async {
    final db = await _dbHelper.database;
    await db.update(
      'receivables',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
    );
  }

  // Hard Delete a receivable
  Future<void> deleteReceivable(int receivableId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'receivables',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
    );
  }

  // Update total received
  Future<void> updateReceivableTotalReceived(
    int receivableId,
    double totalReceived,
  ) async {
    final db = await _dbHelper.database;
    await db.update(
      'receivables',
      {
        'total_received': totalReceived,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
    );
  }

  // Get receivable payments
  Future<List<ReceivablePayment>> getReceivablePayments(
    int receivableId,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receivable_payments',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(
      maps.length,
      (i) => ReceivablePayment.fromMap(maps[i]),
    );
  }

  // Create receivable payment
  Future<int> createReceivablePayment(ReceivablePayment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'receivable_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
