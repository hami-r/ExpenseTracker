import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class CreditCardBillService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> _hasColumn(DatabaseExecutor db, String columnName) async {
    final info = await db.rawQuery('PRAGMA table_info(credit_card_bills)');
    return info.any((row) => row['name'] == columnName);
  }

  Future<void> _ensureSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_card_bills (
        credit_card_bill_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        profile_id INTEGER DEFAULT 1,
        payment_method_id INTEGER NOT NULL,
        bill_month TEXT NOT NULL,
        due_date TEXT NOT NULL,
        amount REAL,
        status TEXT DEFAULT 'pending',
        paid_at TEXT,
        paid_payment_method_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE CASCADE,
        FOREIGN KEY (paid_payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL,
        UNIQUE(user_id, profile_id, payment_method_id, bill_month)
      )
    ''');
    if (!await _hasColumn(db, 'paid_payment_method_id')) {
      await db.execute(
        'ALTER TABLE credit_card_bills ADD COLUMN paid_payment_method_id INTEGER',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_credit_card_bills_month ON credit_card_bills(user_id, profile_id, bill_month)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_credit_card_bills_method ON credit_card_bills(payment_method_id, bill_month)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_credit_card_bills_paid_method ON credit_card_bills(paid_payment_method_id)',
    );
  }

  String _monthKey(DateTime month) => DateFormat('yyyy-MM').format(month);

  DateTime _monthDueDate(DateTime month, int dueDay) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final clampedDay = dueDay.clamp(1, lastDay);
    return DateTime(month.year, month.month, clampedDay);
  }

  Future<int> _resolveDefaultDueDay(DatabaseExecutor db, int methodId) async {
    final latest = await db.query(
      'credit_card_bills',
      columns: ['due_date'],
      where: 'payment_method_id = ?',
      whereArgs: [methodId],
      orderBy: 'bill_month DESC',
      limit: 1,
    );
    if (latest.isNotEmpty && latest.first['due_date'] != null) {
      final parsed = DateTime.tryParse(latest.first['due_date'] as String);
      if (parsed != null) return parsed.day;
    }
    return 5;
  }

  Future<void> _ensureBillsForMonth(
    DatabaseExecutor db,
    int userId,
    int profileId,
    DateTime month,
  ) async {
    await _ensureSchema(db);
    final now = DateTime.now();
    final normalizedMonth = DateTime(month.year, month.month);
    final currentMonth = DateTime(now.year, now.month);
    if (normalizedMonth != currentMonth) {
      return;
    }

    final monthKey = _monthKey(month);
    final cardMethods = await db.query(
      'payment_methods',
      columns: ['payment_method_id', 'bill_generation_day'],
      where:
          'user_id = ? AND profile_id = ? AND is_active = 1 AND LOWER(type) = ?',
      whereArgs: [userId, profileId, 'card'],
      orderBy: 'is_primary DESC, display_order ASC, name ASC',
    );

    for (final method in cardMethods) {
      final paymentMethodId = method['payment_method_id'] as int?;
      if (paymentMethodId == null) continue;
      final configuredDay = (method['bill_generation_day'] as num?)?.toInt();
      final dueDay =
          configuredDay ?? await _resolveDefaultDueDay(db, paymentMethodId);
      final dueDate = _monthDueDate(month, dueDay);
      await db.insert('credit_card_bills', {
        'user_id': userId,
        'profile_id': profileId,
        'payment_method_id': paymentMethodId,
        'bill_month': monthKey,
        'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> getBillsForMonth(
    int userId,
    DateTime month, {
    required int profileId,
  }) async {
    final db = await _dbHelper.database;
    final monthKey = _monthKey(month);

    await db.transaction((txn) async {
      await _ensureSchema(txn);
      await _ensureBillsForMonth(txn, userId, profileId, month);
    });

    return db.rawQuery(
      '''
      SELECT
        b.credit_card_bill_id,
        b.user_id,
        b.profile_id,
        b.payment_method_id,
        b.bill_month,
        b.due_date,
        b.amount,
        b.status,
        b.paid_at,
        b.paid_payment_method_id,
        b.updated_at,
        pm.name AS payment_method_name,
        pm.type AS payment_method_type,
        pm.color_hex AS payment_method_color_hex,
        pm.account_number AS payment_method_account_number,
        ppm.name AS paid_payment_method_name
      FROM credit_card_bills b
      JOIN payment_methods pm ON b.payment_method_id = pm.payment_method_id
      LEFT JOIN payment_methods ppm ON b.paid_payment_method_id = ppm.payment_method_id
      WHERE b.user_id = ?
        AND b.profile_id = ?
        AND b.bill_month = ?
        AND pm.is_active = 1
      ORDER BY b.due_date ASC, pm.name ASC
      ''',
      [userId, profileId, monthKey],
    );
  }

  Future<List<Map<String, dynamic>>> getBillsForYear(
    int userId,
    int year, {
    required int profileId,
    int? cardPaymentMethodId,
  }) async {
    final db = await _dbHelper.database;
    await _ensureSchema(db);
    final fromMonth = '$year-01';
    final toMonth = '$year-12';
    final hasCardFilter = cardPaymentMethodId != null;

    return db.rawQuery(
      '''
      SELECT
        b.credit_card_bill_id,
        b.payment_method_id,
        b.bill_month,
        b.due_date,
        b.status,
        b.amount,
        b.paid_at,
        b.paid_payment_method_id,
        pm.name AS payment_method_name
      FROM credit_card_bills b
      JOIN payment_methods pm ON b.payment_method_id = pm.payment_method_id
      WHERE b.user_id = ?
        AND b.profile_id = ?
        AND b.bill_month >= ?
        AND b.bill_month <= ?
        AND pm.is_active = 1
        AND (? IS NULL OR b.payment_method_id = ?)
      ORDER BY b.bill_month ASC, b.due_date ASC
      ''',
      [
        userId,
        profileId,
        fromMonth,
        toMonth,
        hasCardFilter ? cardPaymentMethodId : null,
        hasCardFilter ? cardPaymentMethodId : -1,
      ],
    );
  }

  Future<void> markBillStatus({
    required int billId,
    required bool isPaid,
    int? paidPaymentMethodId,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'credit_card_bills',
      {
        'status': isPaid ? 'paid' : 'pending',
        'paid_at': isPaid ? DateTime.now().toIso8601String() : null,
        'paid_payment_method_id': isPaid ? paidPaymentMethodId : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'credit_card_bill_id = ?',
      whereArgs: [billId],
    );
  }

  Future<void> updateBillDetails({
    required int billId,
    required DateTime dueDate,
    double? amount,
    int? paidPaymentMethodId,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'credit_card_bills',
      {
        'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
        'amount': amount,
        'paid_payment_method_id': paidPaymentMethodId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'credit_card_bill_id = ?',
      whereArgs: [billId],
    );
  }
}
