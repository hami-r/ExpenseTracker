import '../../models/category.dart';
import '../database_helper.dart';

class CategorySpending {
  final Category category;
  final double amount;

  CategorySpending({required this.category, required this.amount});
}

class AnalyticsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get weekly spending (last 7 days)
  Future<Map<String, double>> getWeeklySpending(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    final Map<String, double> weeklyData = {};

    for (int i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM transactions
        WHERE user_id = ? AND transaction_date = ? AND parent_transaction_id IS NULL
      ''',
        [userId, dateStr],
      );

      final dayName = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][date.weekday - 1];
      weeklyData[dayName] = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    return weeklyData;
  }

  // Get total balance (sum of all transactions)
  Future<double> getTotalBalance(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? AND parent_transaction_id IS NULL
    ''',
      [userId],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total liabilities (loans + IOUs)
  Future<double> getTotalLiabilities(int userId) async {
    final db = await _dbHelper.database;

    final loansResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(principal_amount - total_paid), 0) as total
      FROM loans
      WHERE user_id = ? AND status = 'active'
    ''',
      [userId],
    );

    final iousResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount - total_paid), 0) as total
      FROM ious
      WHERE user_id = ? AND status = 'active'
    ''',
      [userId],
    );

    final loansTotal = (loansResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final iousTotal = (iousResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return loansTotal + iousTotal;
  }

  // Get total receivables
  Future<double> getTotalReceivables(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(principal_amount - total_received), 0) as total
      FROM receivables
      WHERE user_id = ? AND status = 'active'
    ''',
      [userId],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get daily spending by month
  Future<Map<int, double>> getDailySpendingByMonth(
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

    final result = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%d', transaction_date) AS INTEGER) as day,
        SUM(amount) as total
      FROM transactions
      WHERE user_id = ? 
        AND transaction_date >= ? 
        AND transaction_date <= ?
        AND parent_transaction_id IS NULL
      GROUP BY day
    ''',
      [userId, startDate, endDate],
    );

    final Map<int, double> dailyData = {};
    for (final row in result) {
      final day = row['day'] as int;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      dailyData[day] = total;
    }

    return dailyData;
  }

  // Get spending by category
  Future<Map<Category, double>> getSpendingByCategory(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      '''
      SELECT 
        c.*,
        COALESCE(SUM(t.amount), 0) as total
      FROM categories c
      LEFT JOIN transactions t ON c.category_id = t.category_id
        AND t.user_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
        AND t.parent_transaction_id IS NULL
      WHERE c.user_id = ? AND c.is_active = 1
      GROUP BY c.category_id
      HAVING total > 0
      ORDER BY total DESC
    ''',
      [userId, startDateStr, endDateStr, userId],
    );

    final Map<Category, double> categorySpending = {};
    for (final row in result) {
      final category = Category.fromMap(row);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      categorySpending[category] = total;
    }

    return categorySpending;
  }

  // Get top categories
  Future<List<CategorySpending>> getTopCategories(
    int userId,
    DateTime startDate,
    DateTime endDate,
    int limit,
  ) async {
    final db = await _dbHelper.database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      '''
      SELECT 
        c.*,
        SUM(t.amount) as total
      FROM categories c
      INNER JOIN transactions t ON c.category_id = t.category_id
      WHERE t.user_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
        AND t.parent_transaction_id IS NULL
      GROUP BY c.category_id
      ORDER BY total DESC
      LIMIT ?
    ''',
      [userId, startDateStr, endDateStr, limit],
    );

    final List<CategorySpending> topCategories = [];
    for (final row in result) {
      final category = Category.fromMap(row);
      final total = (row['total'] as num).toDouble();
      topCategories.add(CategorySpending(category: category, amount: total));
    }

    return topCategories;
  }

  // Get total spending in date range
  Future<double> getTotalSpending(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? 
        AND transaction_date >= ? 
        AND transaction_date <= ?
        AND parent_transaction_id IS NULL
    ''',
      [userId, startDateStr, endDateStr],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
