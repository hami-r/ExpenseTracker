import 'package:sqflite/sqflite.dart';
import '../../models/iou.dart';
import '../../models/iou_payment.dart';
import '../database_helper.dart';

class IOUService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get active IOUs
  Future<List<IOU>> getActiveIOUs(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ious',
      where: 'user_id = ? AND status = ? AND is_deleted = 0',
      whereArgs: [userId, 'active'],
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => IOU.fromMap(maps[i]));
  }

  // Get IOU by ID
  Future<IOU?> getIOUById(int iouId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ious',
      where: 'iou_id = ? AND is_deleted = 0',
      whereArgs: [iouId],
    );
    if (maps.isEmpty) return null;
    return IOU.fromMap(maps.first);
  }

  // Create new IOU
  Future<int> createIOU(IOU iou) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'ious',
      iou.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update IOU
  Future<void> updateIOU(IOU iou) async {
    final db = await _dbHelper.database;
    await db.update(
      'ious',
      iou.toMap(),
      where: 'iou_id = ?',
      whereArgs: [iou.iouId],
    );
  }

  // Delete IOU
  Future<void> deleteIOU(int iouId) async {
    final db = await _dbHelper.database;
    await db.delete('ious', where: 'iou_id = ?', whereArgs: [iouId]);
  }

  // Soft delete IOU
  Future<void> softDeleteIOU(int iouId) async {
    final db = await _dbHelper.database;
    await db.update(
      'ious',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'iou_id = ?',
      whereArgs: [iouId],
    );
  }

  // Update total paid
  Future<void> updateIOUTotalPaid(int iouId, double totalPaid) async {
    final db = await _dbHelper.database;
    await db.update(
      'ious',
      {'total_paid': totalPaid, 'updated_at': DateTime.now().toIso8601String()},
      where: 'iou_id = ?',
      whereArgs: [iouId],
    );
  }

  // Get IOU payments
  Future<List<IOUPayment>> getIOUPayments(int iouId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'iou_payments',
      where: 'iou_id = ?',
      whereArgs: [iouId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => IOUPayment.fromMap(maps[i]));
  }

  // Create IOU payment
  Future<int> createIOUPayment(IOUPayment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'iou_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
