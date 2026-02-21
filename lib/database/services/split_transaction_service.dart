import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../models/transaction.dart' as model;
import '../../models/split_item.dart';
import '../database_helper.dart';

class SplitTransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create split transaction with items
  Future<int> createSplitTransaction(
    model.Transaction mainTransaction,
    List<SplitItem> splitItems, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Create main expense transaction
      final mainMap = mainTransaction.toMap();
      if (profileId != null) mainMap['profile_id'] = profileId;
      final transactionId = await txn.insert(
        'transactions',
        mainMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert split items
      for (final item in splitItems) {
        await txn.insert(
          'split_items',
          item.toMap()..['transaction_id'] = transactionId,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return transactionId;
    });
  }

  // Update split transaction with items
  Future<void> updateSplitTransaction(
    model.Transaction transaction,
    List<SplitItem> items, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Update parent transaction
      final mainMap = transaction.toMap();
      if (profileId != null) mainMap['profile_id'] = profileId;
      await txn.update(
        'transactions',
        mainMap,
        where: 'transaction_id = ?',
        whereArgs: [transaction.transactionId],
      );

      // Delete existing split items
      await txn.delete(
        'split_items',
        where: 'transaction_id = ?',
        whereArgs: [transaction.transactionId],
      );

      // Insert new split items
      for (final item in items) {
        await txn.insert(
          'split_items',
          item.toMap()..['transaction_id'] = transaction.transactionId,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get split items by transaction
  Future<List<SplitItem>> getSplitItemsByTransaction(int transactionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'split_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => SplitItem.fromMap(maps[i]));
  }

  // Create single split item
  Future<int> createSplitItem(SplitItem splitItem) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'split_items',
      splitItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update split item
  Future<void> updateSplitItem(SplitItem splitItem) async {
    final db = await _dbHelper.database;
    await db.update(
      'split_items',
      splitItem.toMap(),
      where: 'split_item_id = ?',
      whereArgs: [splitItem.splitItemId],
    );
  }

  // Delete split item
  Future<void> deleteSplitItem(int splitItemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'split_items',
      where: 'split_item_id = ?',
      whereArgs: [splitItemId],
    );
  }

  // Delete split transaction (deletes parent and all items due to CASCADE)
  Future<void> deleteSplitTransaction(int transactionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }
}
