import 'package:sqflite/sqflite.dart';
import '../../models/loan.dart';
import '../../models/loan_payment.dart';
import '../database_helper.dart';

class LoanService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Get active loans
  Future<List<Loan>> getActiveLoans(int userId, {int? profileId}) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, 'active', profileId]
        : [userId, 'active'];
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'user_id = ? AND status = ? AND is_deleted = 0$profileClause',
      whereArgs: args,
      orderBy: 'due_date ASC',
    );
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  // Get completed loans
  Future<List<Loan>> getCompletedLoans(int userId, {int? profileId}) async {
    final db = await _dbHelper.database;
    final profileClause = profileId != null ? ' AND profile_id = ?' : '';
    final args = profileId != null
        ? [userId, 'completed', profileId]
        : [userId, 'completed'];
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'user_id = ? AND status = ? AND is_deleted = 0$profileClause',
      whereArgs: args,
      orderBy: 'updated_at DESC, due_date DESC',
    );
    return List.generate(maps.length, (i) => Loan.fromMap(maps[i]));
  }

  // Get loan by ID
  Future<Loan?> getLoanById(int loanId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'loan_id = ? AND is_deleted = 0',
      whereArgs: [loanId],
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  // Create new loan
  Future<int> createLoan(Loan loan, {int? profileId}) async {
    final db = await _dbHelper.database;
    final map = loan.toMap();
    if (profileId != null) map['profile_id'] = profileId;
    return await db.insert(
      'loans',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update loan
  Future<void> updateLoan(Loan loan, {int? profileId}) async {
    final db = await _dbHelper.database;
    final map = loan.toMap();
    if (profileId != null) map['profile_id'] = profileId;
    await db.update(
      'loans',
      map,
      where: 'loan_id = ?',
      whereArgs: [loan.loanId],
    );
  }

  // Delete loan
  Future<void> deleteLoan(int loanId) async {
    final db = await _dbHelper.database;
    await db.delete('loans', where: 'loan_id = ?', whereArgs: [loanId]);
  }

  // Soft delete loan
  Future<void> softDeleteLoan(int loanId) async {
    final db = await _dbHelper.database;
    await db.update(
      'loans',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  // Update total paid
  Future<void> updateLoanTotalPaid(int loanId, double totalPaid) async {
    final db = await _dbHelper.database;
    final clampedTotalPaid = totalPaid < 0 ? 0.0 : totalPaid;
    await db.rawUpdate(
      '''
      UPDATE loans
      SET
        total_paid = ?,
        status = CASE
          WHEN ? >= principal_amount THEN 'completed'
          ELSE 'active'
        END,
        updated_at = ?
      WHERE loan_id = ?
      ''',
      [
        clampedTotalPaid,
        clampedTotalPaid,
        DateTime.now().toIso8601String(),
        loanId,
      ],
    );
  }

  // Get loan payments
  Future<List<LoanPayment>> getLoanPayments(int loanId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => LoanPayment.fromMap(maps[i]));
  }

  // Create loan payment
  Future<int> createLoanPayment(LoanPayment payment) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'loan_payments',
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete loan payment
  Future<void> deleteLoanPayment(int paymentId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'loan_payments',
      where: 'loan_payment_id = ?',
      whereArgs: [paymentId],
    );
  }
}
