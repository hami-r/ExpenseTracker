import 'package:flutter/foundation.dart';

import '../database_helper.dart';
import '../../models/transaction_item.dart';

enum TransactionSortOption { dateDesc, dateAsc, amountHighLow, amountLowHigh }

class AllTransactionsService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Future<List<TransactionItem>> getTransactions({
    int limit = 20,
    int offset = 0,
    TransactionSortOption sortOption = TransactionSortOption.dateDesc,
    List<TransactionType>? typeFilter,
    int? profileId,
  }) async {
    final db = await _dbHelper.database;

    String typeFilterClause = '';
    if (typeFilter != null && typeFilter.isNotEmpty) {
      final types = typeFilter.map((e) => "'${e.name}'").join(',');
      typeFilterClause = 'WHERE type IN ($types)';
    }

    // Profile clauses (qualified per query to avoid ambiguous column names)
    final p = profileId;
    final String transactionsProfileClause = p != null
        ? ' AND t.profile_id = $p'
        : '';
    final String loansProfileClause = p != null
        ? ' AND loans.profile_id = $p'
        : '';
    final String iousProfileClause = p != null
        ? ' AND ious.profile_id = $p'
        : '';
    final String receivablesProfileClause = p != null
        ? ' AND receivables.profile_id = $p'
        : '';
    final String reimbursementsProfileClause = p != null
        ? ' WHERE reimbursements.profile_id = $p'
        : '';

    final transactionsQuery =
        '''
      SELECT 
        t.transaction_id as id,
        t.user_id as user_id,
        'expense' as type,
        t.amount as amount,
        t.transaction_date as date,
        COALESCE(NULLIF(TRIM(t.note), ''), c.name, 'Expense') as title,
        t.note as subtitle,
        t.is_split as is_split,
        t.category_id as category_id,
        c.name as category_name,
        t.payment_method_id as payment_method_id,
        pm.name as payment_method_name,
        c.color_hex as color_hex,
        'paid' as status
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.category_id
      LEFT JOIN payment_methods pm ON t.payment_method_id = pm.payment_method_id
      WHERE t.parent_transaction_id IS NULL$transactionsProfileClause
    ''';

    final loansQuery =
        '''
      SELECT 
        loan_id as id,
        user_id as user_id,
        'loan' as type,
        principal_amount as amount,
        start_date as date,
        lender_name as title,
        'Loan Taken' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#F43F5E' as color_hex,
        status as status
      FROM loans
      WHERE is_deleted = 0$loansProfileClause
    ''';

    final loanPaymentsQuery =
        '''
      SELECT 
        lp.loan_id as id,
        l.user_id as user_id,
        'loanPayment' as type,
        lp.payment_amount as amount,
        lp.payment_date as date,
        l.lender_name as title,
        'Loan Repayment' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#10B981' as color_hex,
        'paid' as status
      FROM loan_payments lp
      JOIN loans l ON lp.loan_id = l.loan_id
      ${p != null ? 'WHERE l.profile_id = $p' : ''}
    ''';

    final iousQuery =
        '''
      SELECT 
        iou_id as id,
        user_id as user_id,
        'iou' as type,
        amount as amount,
        COALESCE(created_at, date('now')) as date,
        creditor_name as title,
        'IOU Added' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#F43F5E' as color_hex,
        status as status
      FROM ious
      WHERE is_deleted = 0$iousProfileClause
    ''';

    final iouPaymentsQuery =
        '''
      SELECT 
        ip.iou_id as id,
        i.user_id as user_id,
        'iouPayment' as type,
        ip.payment_amount as amount,
        ip.payment_date as date,
        i.creditor_name as title,
        'IOU Payment' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#10B981' as color_hex,
        'paid' as status
      FROM iou_payments ip
      JOIN ious i ON ip.iou_id = i.iou_id
      ${p != null ? 'WHERE i.profile_id = $p' : ''}
    ''';

    final receivablesQuery =
        '''
      SELECT 
        receivable_id as id,
        user_id as user_id,
        'receivable' as type,
        principal_amount as amount,
        COALESCE(created_at, date('now')) as date,
        recipient_name as title,
        'Money Lent' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#F59E0B' as color_hex,
        status as status
      FROM receivables
      WHERE is_deleted = 0$receivablesProfileClause
    ''';

    final receivablePaymentsQuery =
        '''
      SELECT 
        rp.receivable_id as id,
        r.user_id as user_id,
        'receivablePayment' as type,
        rp.payment_amount as amount,
        rp.payment_date as date,
        r.recipient_name as title,
        'Received Payment' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#10B981' as color_hex,
        'paid' as status
      FROM receivable_payments rp
      JOIN receivables r ON rp.receivable_id = r.receivable_id
      ${p != null ? 'WHERE r.profile_id = $p' : ''}
    ''';

    final reimbursementsQuery =
        '''
      SELECT 
        reimbursement_id as id,
        user_id as user_id,
        'reimbursement' as type,
        amount as amount,
        COALESCE(created_at, date('now')) as date,
        source_name as title,
        'Reimbursement Expected' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#F59E0B' as color_hex,
        status as status
      FROM reimbursements
      $reimbursementsProfileClause
    ''';

    final reimbursementPaymentsQuery =
        '''
      SELECT 
        rp.reimbursement_id as id,
        r.user_id as user_id,
        'reimbursementPayment' as type,
        rp.payment_amount as amount,
        rp.payment_date as date,
        r.source_name as title,
        'Reimbursement Received' as subtitle,
        0 as is_split,
        NULL as category_id,
        NULL as category_name,
        NULL as payment_method_id,
        NULL as payment_method_name,
        '#10B981' as color_hex,
        'paid' as status
      FROM reimbursement_payments rp
      JOIN reimbursements r ON rp.reimbursement_id = r.reimbursement_id
      ${p != null ? 'WHERE r.profile_id = $p' : ''}
    ''';

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
          userId: _asInt(row['user_id']),
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['date'] as String),
          title: row['title'] as String? ?? 'Unknown',
          subtitle: row['subtitle'] as String?,
          type: _parseTransactionType(row['type'] as String),
          status: row['status'] as String?,
          isSplit: (row['is_split'] as int) == 1,
          categoryId: _asInt(row['category_id']),
          paymentMethodId: _asInt(row['payment_method_id']),
          paymentMethodName: row['payment_method_name'] as String?,
          categoryName: row['category_name'] as String?,
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
        return "strftime('%Y-%m', date) DESC, amount DESC";
      case TransactionSortOption.amountLowHigh:
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
