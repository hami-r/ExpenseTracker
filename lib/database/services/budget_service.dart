import 'package:sqflite/sqflite.dart';
import '../../models/budget.dart';
import '../database_helper.dart';

class BudgetService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Save or update a budget limit, and forward-sync to future months
  Future<void> saveBudget(Budget budget) async {
    final db = await _dbHelper.database;

    final profileClause = budget.profileId != null ? ' AND profile_id = ?' : '';
    final args = budget.profileId != null
        ? [
            budget.userId,
            budget.month,
            budget.year,
            budget.categoryId,
            budget.categoryId,
            budget.profileId,
          ]
        : [
            budget.userId,
            budget.month,
            budget.year,
            budget.categoryId,
            budget.categoryId,
          ];

    // Check if a budget already exists for this month
    final List<Map<String, dynamic>> existing = await db.query(
      'budgets',
      where:
          'user_id = ? AND month = ? AND year = ? AND (category_id IS ? OR category_id = ?)$profileClause',
      whereArgs: args,
    );

    if (existing.isNotEmpty) {
      // Update current month
      final existingBudget = Budget.fromMap(existing.first);
      await db.update(
        'budgets',
        budget.copyWith(budgetId: existingBudget.budgetId).toMap(),
        where: 'budget_id = ?',
        whereArgs: [existingBudget.budgetId],
      );
    } else {
      // Insert for current month
      await db.insert(
        'budgets',
        budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Forward-sync: update the same category in any future months that already have a budget row
    // This never touches records older than (budget.year, budget.month)
    if (budget.categoryId != null) {
      final updateProfileClause = budget.profileId != null
          ? ' AND profile_id = ?'
          : '';
      final updateArgs = budget.profileId != null
          ? [
              budget.amount,
              DateTime.now().toIso8601String(),
              budget.userId,
              budget.categoryId,
              budget.year,
              budget.year,
              budget.month,
              budget.profileId,
            ]
          : [
              budget.amount,
              DateTime.now().toIso8601String(),
              budget.userId,
              budget.categoryId,
              budget.year,
              budget.year,
              budget.month,
            ];

      await db.rawUpdate('''
        UPDATE budgets
        SET amount = ?, updated_at = ?
        WHERE user_id = ?
          AND category_id = ?
          AND (year > ? OR (year = ? AND month > ?))
          $updateProfileClause
        ''', updateArgs);
    }
  }

  // Fetch budgets for a given user, month, and year.
  // Performs the auto-carry-over cloning if nothing exists for this month.
  Future<List<Budget>> getBudgets(
    int userId,
    int month,
    int year, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, month, year, profileId]
        : [userId, month, year];

    List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'user_id = ? AND month = ? AND year = ?$profileClause',
      whereArgs: args,
    );

    // If budgets exist for this month, return them
    if (maps.isNotEmpty) {
      return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
    }

    // Auto-Carry-Over Requirement: The budget goes to the next month as well
    // Let's find the most recent month before this one that has budgets
    final pastArgs = profileId != null
        ? [userId, year, year, month, profileId]
        : [userId, year, year, month];
    final List<Map<String, dynamic>> pastBudgetsResult = await db.rawQuery('''
      SELECT * FROM budgets 
      WHERE user_id = ? 
        AND (year < ? OR (year = ? AND month < ?))
        $profileClause
      ORDER BY year DESC, month DESC 
    ''', pastArgs);

    if (pastBudgetsResult.isEmpty) {
      return []; // True empty state
    }

    // Isolate the budgets belonging to that most recent previous config
    final int pastYear = pastBudgetsResult.first['year'] as int;
    final int pastMonth = pastBudgetsResult.first['month'] as int;

    final latestPastBudgets = pastBudgetsResult
        .where((row) => row['year'] == pastYear && row['month'] == pastMonth)
        .toList();

    // Clone them into the requested (new) month
    final List<Budget> clonedBudgets = [];
    await db.transaction((txn) async {
      for (var row in latestPastBudgets) {
        final clonedBudget = Budget(
          userId: userId,
          profileId: profileId,
          categoryId: row['category_id'] as int?,
          amount: (row['amount'] as num).toDouble(),
          month: month,
          year: year,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await txn.insert('budgets', clonedBudget.toMap());
        clonedBudgets.add(clonedBudget.copyWith(budgetId: id));
      }
    });

    return clonedBudgets;
  }

  // Fetch the actual spending data for a user this month.
  // Returns a map where:
  // key: categoryId (null meaning 'Overall')
  // value: total spent (double)
  Future<Map<int?, double>> getMonthlySpending(
    int userId,
    int month,
    int year, {
    int? profileId,
  }) async {
    final db = await _dbHelper.database;

    // Start of month
    final startDate = DateTime(year, month, 1).toIso8601String();

    // End of month
    // If month is 12, next month is year+1, month=1.
    final endYear = month == 12 ? year + 1 : year;
    final endMonth = month == 12 ? 1 : month + 1;
    final endDate = DateTime(endYear, endMonth, 1).toIso8601String();

    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, startDate, endDate, profileId]
        : [userId, startDate, endDate];

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total_spent
      FROM transactions
      WHERE user_id = ? 
        AND parent_transaction_id IS NULL
        AND transaction_date >= ?
        AND transaction_date < ?
        $profileClause
      GROUP BY category_id
    ''', args);

    final Map<int?, double> spending = {};
    double overallSpent = 0.0;

    for (var row in result) {
      final catId = row['category_id'] as int?;
      final amount = (row['total_spent'] as num).toDouble();
      spending[catId] = amount;
      overallSpent += amount;
    }

    // Set overall spending
    spending[null] = overallSpent;

    return spending;
  }
}
