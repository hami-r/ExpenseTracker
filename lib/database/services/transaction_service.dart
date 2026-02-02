import 'package:sqflite/sqflite.dart';
import '../../models/transaction.dart' as model;
import '../database_helper.dart';

class TransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get recent transactions with limit
  Future<List<model.Transaction>> getRecentTransactions(int userId, int limit) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ? AND parent_transaction_id IS NULL',
      whereArgs: [userId],
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  // Get today's transactions
  Future<List<model.Transaction>> getTodayTransactions(int userId) async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where:
          'user_id = ? AND transaction_date = ? AND parent_transaction_id IS NULL',
      whereArgs: [userId, today],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  // Get transactions by specific date
  Future<List<model.Transaction>> getTransactionsByDate(
    int userId,
    DateTime date,
  ) async {
    final db = await _dbHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where:
          'user_id = ? AND transaction_date = ? AND parent_transaction_id IS NULL',
      whereArgs: [userId, dateStr],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  // Get transactions by month
  Future<List<model.Transaction>> getTransactionsByMonth(
    int userId,
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1).toIso8601String().split('T')[0];
    final endDate = DateTime(
      year,
      month + 1,
      0,
    ).toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where:
          'user_id = ? AND transaction_date >= ? AND transaction_date <= ? AND parent_transaction_id IS NULL',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'transaction_date DESC',
    );
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  // Get transaction by ID
  Future<model.Transaction?> getTransactionById(int transactionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    if (maps.isEmpty) return null;
    return model.Transaction.fromMap(maps.first);
  }

  // Create new transaction
  Future<int> createTransaction(model.Transaction transaction) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update transaction
  Future<void> updateTransaction(model.Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'transaction_id = ?',
      whereArgs: [transaction.transactionId],
    );
  }

  // Delete transaction
  Future<void> deleteTransaction(int transactionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }
}
