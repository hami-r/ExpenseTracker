import 'package:flutter/foundation.dart';

import '../database_helper.dart';
import '../../models/transaction_item.dart';

enum TransactionSortOption {
  dateDesc,
  dateAsc,
  amountHighLow, // Within month group
  amountLowHigh, // Within month group
}

class AllTransactionsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<TransactionItem>> getTransactions({
    int limit = 20,
    int offset = 0,
    TransactionSortOption sortOption = TransactionSortOption.dateDesc,
    List<TransactionType>? typeFilter,
  }) async {
    final db = await _dbHelper.database;

    // Helper to format list for SQL IN clause
    String typeFilterClause = '';
    if (typeFilter != null && typeFilter.isNotEmpty) {
      // mapping enum to string values used in the union query
      final types = typeFilter.map((e) => "'${e.name}'").join(',');
      typeFilterClause = 'WHERE type IN ($types)';
    }

    // Base queries for each table
    // 1. Transactions (Expenses)
    // Note: We cast amount to Real.
    // We select 'expense' as type string.
    // Title is Category Name, Subtitle is Note.
    final transactionsQuery = '''
      SELECT 
        t.transaction_id as id,
        'expense' as type,
        t.amount as amount,
        t.transaction_date as date,
        c.name as title,
        t.note as subtitle,
        t.is_split as is_split,
        c.color_hex as color_hex,
        'paid' as status
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.category_id
      WHERE t.parent_transaction_id IS NULL
    ''';

    // 2. Loans (Incoming money/Debt)
    final loansQuery = '''
      SELECT 
        loan_id as id,
        'loan' as type,
        principal_amount as amount,
        start_date as date,
        lender_name as title,
        'Loan Taken' as subtitle,
        0 as is_split,
        '#F43F5E' as color_hex, -- Redish for debt
        status as status
      FROM loans
    ''';

    // 3. Loan Payments (Outgoing money/Repayment)
    final loanPaymentsQuery = '''
      SELECT 
        lp.loan_payment_id as id,
        'loanPayment' as type,
        lp.payment_amount as amount,
        lp.payment_date as date,
        l.lender_name as title,
        'Loan Repayment' as subtitle,
        0 as is_split,
        '#10B981' as color_hex, -- Greenish for paying off? Or Red for visual consistency with loan? Let's use Neutral/Blue.
        'paid' as status
      FROM loan_payments lp
      JOIN loans l ON lp.loan_id = l.loan_id
    ''';

    // 4. IOUs (Outgoing money/Debt to separate mostly?)
    // Wait, IOU in this app context usually means "I Owe You" (Debt).
    // Let's treat it similar to Loan.
    final iousQuery = '''
      SELECT 
        iou_id as id,
        'iou' as type,
        amount as amount,
        COALESCE(created_at, date('now')) as date, -- Fallback if created_at is strictly timestamp
        creditor_name as title,
        'IOU Added' as subtitle,
        0 as is_split,
        '#F43F5E' as color_hex,
        status as status
      FROM ious
    ''';

    // 5. IOU Payments
    final iouPaymentsQuery = '''
      SELECT 
        ip.iou_payment_id as id,
        'iouPayment' as type,
        ip.payment_amount as amount,
        ip.payment_date as date,
        i.creditor_name as title,
        'IOU Payment' as subtitle,
        0 as is_split,
        '#10B981' as color_hex,
        'paid' as status
      FROM iou_payments ip
      JOIN ious i ON ip.iou_id = i.iou_id
    ''';

    // 6. Receivables (Money Lending - Outgoing initially?)
    final receivablesQuery = '''
      SELECT 
        receivable_id as id,
        'receivable' as type,
        principal_amount as amount,
        COALESCE(created_at, date('now')) as date,
        recipient_name as title,
        'Money Lent' as subtitle,
        0 as is_split,
        '#F59E0B' as color_hex, -- Amber for pending return
        status as status
      FROM receivables
    ''';

    // 7. Receivable Payments (Money Incoming)
    final receivablePaymentsQuery = '''
      SELECT 
        rp.receivable_payment_id as id,
        'receivablePayment' as type,
        rp.payment_amount as amount,
        rp.payment_date as date,
        r.recipient_name as title,
        'Received Payment' as subtitle,
        0 as is_split,
        '#10B981' as color_hex,
        'paid' as status
      FROM receivable_payments rp
      JOIN receivables r ON rp.receivable_id = r.receivable_id
    ''';

    // 8. Reimbursements (Money expected back)
    final reimbursementsQuery = '''
      SELECT 
        reimbursement_id as id,
        'reimbursement' as type,
        amount as amount,
        COALESCE(created_at, date('now')) as date,
        source_name as title,
        'Reimbursement Expected' as subtitle,
        0 as is_split,
        '#F59E0B' as color_hex,
        status as status
      FROM reimbursements
    ''';

    // 9. Reimbursement Payments (Money Incoming)
    final reimbursementPaymentsQuery = '''
      SELECT 
        rp.reimbursement_payment_id as id,
        'reimbursementPayment' as type,
        rp.payment_amount as amount,
        rp.payment_date as date,
        r.source_name as title,
        'Reimbursement Received' as subtitle,
        0 as is_split,
        '#10B981' as color_hex,
        'paid' as status
      FROM reimbursement_payments rp
      JOIN reimbursements r ON rp.reimbursement_id = r.reimbursement_id
    ''';

    // Combine all
    final fullQuery =
        '''
      SELECT * FROM (
        $transactionsQuery
        UNION ALL
        $loansQuery
        UNION ALL
        $loanPaymentsQuery
        UNION ALL
        $iousQuery
        UNION ALL
        $iouPaymentsQuery
        UNION ALL
        $receivablesQuery
        UNION ALL
        $receivablePaymentsQuery
        UNION ALL
        $reimbursementsQuery
        UNION ALL
        $reimbursementPaymentsQuery
      ) as combined_transactions
      $typeFilterClause
      ORDER BY ${_getOrderByClause(sortOption)}
      LIMIT $limit OFFSET $offset
    ''';

    try {
      final List<Map<String, dynamic>> results = await db.rawQuery(fullQuery);

      return results.map((row) {
        return TransactionItem(
          id: row['id'] as int,
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['date'] as String),
          title: row['title'] as String? ?? 'Unknown',
          subtitle: row['subtitle'] as String?,
          type: _parseTransactionType(row['type'] as String),
          status: row['status'] as String?,
          isSplit: (row['is_split'] as int) == 1,
          colorHex: row['color_hex'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching all transactions: $e');
      return [];
    }
  }

  String _getOrderByClause(TransactionSortOption option) {
    switch (option) {
      case TransactionSortOption.dateDesc:
        return 'date DESC';
      case TransactionSortOption.dateAsc:
        return 'date ASC';
      case TransactionSortOption.amountHighLow:
        // Sort by Month DESC first, then Amount DESC
        return "strftime('%Y-%m', date) DESC, amount DESC";
      case TransactionSortOption.amountLowHigh:
        // Sort by Month DESC first, then Amount ASC
        return "strftime('%Y-%m', date) DESC, amount ASC";
    }
  }

  TransactionType _parseTransactionType(String type) {
    return TransactionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TransactionType.expense,
    );
  }
}
