import 'package:sqflite/sqflite.dart';
import '../../models/payment_method.dart';
import '../database_helper.dart';

class PaymentMethodService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get all payment methods for a user (optionally scoped to a profile)
  Future<List<PaymentMethod>> getAllPaymentMethods(
    int userId, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null ? [userId, profileId] : [userId];
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'user_id = ? AND is_active = 1$profileClause',
      whereArgs: args,
      orderBy: 'is_primary DESC, display_order ASC, name ASC',
    );
    return List.generate(maps.length, (i) => PaymentMethod.fromMap(maps[i]));
  }

  // Get payment method by ID
  Future<PaymentMethod?> getPaymentMethodById(int paymentMethodId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      where: 'payment_method_id = ?',
      whereArgs: [paymentMethodId],
    );
    if (maps.isEmpty) return null;
    return PaymentMethod.fromMap(maps.first);
  }

  // Create new payment method
  Future<int> createPaymentMethod(
    PaymentMethod paymentMethod, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final map = paymentMethod.toMap();
      if (profileId != null) map['profile_id'] = profileId;

      if (paymentMethod.isPrimary) {
        final where = profileId != null
            ? 'user_id = ? AND profile_id = ?'
            : 'user_id = ?';
        final args = profileId != null
            ? [paymentMethod.userId, profileId]
            : [paymentMethod.userId];
        await txn.update(
          'payment_methods',
          {'is_primary': 0},
          where: where,
          whereArgs: args,
        );
      }

      return await txn.insert(
        'payment_methods',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // Update payment method
  Future<void> updatePaymentMethod(
    PaymentMethod paymentMethod, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final map = paymentMethod.toMap();
      if (profileId != null) map['profile_id'] = profileId;

      if (paymentMethod.isPrimary) {
        final where = profileId != null
            ? 'user_id = ? AND profile_id = ? AND payment_method_id != ?'
            : 'user_id = ? AND payment_method_id != ?';
        final args = profileId != null
            ? [paymentMethod.userId, profileId, paymentMethod.paymentMethodId]
            : [paymentMethod.userId, paymentMethod.paymentMethodId];
        await txn.update(
          'payment_methods',
          {'is_primary': 0},
          where: where,
          whereArgs: args,
        );
      }

      await txn.update(
        'payment_methods',
        map,
        where: 'payment_method_id = ?',
        whereArgs: [paymentMethod.paymentMethodId],
      );
    });
  }

  // Deactivate payment method (soft delete)
  Future<void> deactivatePaymentMethod(int paymentMethodId) async {
    final db = await _dbHelper.database;
    await db.update(
      'payment_methods',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'payment_method_id = ?',
      whereArgs: [paymentMethodId],
    );
  }
}
