import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../database/services/budget_service.dart';
import '../database/services/category_service.dart';
import '../database/services/iou_service.dart';
import '../database/services/loan_service.dart';
import '../database/services/reimbursement_service.dart';
import '../database/services/receivable_service.dart';
import '../models/category.dart';
import '../models/iou.dart';
import '../models/iou_payment.dart';
import '../models/loan.dart';
import '../models/loan_payment.dart';
import '../models/reimbursement.dart';
import '../models/reimbursement_payment.dart';
import '../models/receivable.dart';
import '../models/receivable_payment.dart';
import '../models/therapist_scoped_preview.dart';

class FinancialTherapistScopeService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CategoryService _categoryService = CategoryService();
  final BudgetService _budgetService = BudgetService();
  final LoanService _loanService = LoanService();
  final IOUService _iouService = IOUService();
  final ReceivableService _receivableService = ReceivableService();
  final ReimbursementService _reimbursementService = ReimbursementService();

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  Future<TherapistScopedResolution?> resolveTextRequest({
    required String text,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final intent = _detectIntent(text);
    final kind = await _detectKind(text, userId);

    if (intent == null || kind == null) return null;

    return _buildResolution(
      text: text,
      intent: intent,
      kind: kind,
      userId: userId,
      profileId: profileId,
      currencySymbol: currencySymbol,
    );
  }

  Future<TherapistScopedResolution> buildQuickAction({
    required TherapistScopedDataKind kind,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) {
    final seedText = switch (kind) {
      TherapistScopedDataKind.expenses => 'last 7 days expenses',
      TherapistScopedDataKind.budget => 'this month budget',
      TherapistScopedDataKind.loan => 'loan details',
      TherapistScopedDataKind.iou => 'iou details',
      TherapistScopedDataKind.receivable => 'lent details',
      TherapistScopedDataKind.reimbursement => 'reimbursement details',
    };

    return _buildResolution(
      text: seedText,
      intent: intent,
      kind: kind,
      userId: userId,
      profileId: profileId,
      currencySymbol: currencySymbol,
    );
  }

  Future<TherapistScopedResolution> buildExpensePreviewForRange({
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
    required DateTime start,
    required DateTime end,
    int? categoryId,
  }) async {
    final categories = await _categoryService.getAllCategories(userId);
    Category? category;
    if (categoryId != null) {
      for (final item in categories) {
        if (item.categoryId == categoryId) {
          category = item;
          break;
        }
      }
    }
    final range = _ResolvedRange(
      start: start,
      end: end,
      label: _formatRangeLabel(start, end),
    );

    final transactions = await _fetchExpenseRows(
      userId: userId,
      profileId: profileId,
      start: start,
      end: end,
      categoryId: categoryId,
    );

    return _buildExpenseResolution(
      transactions: transactions,
      range: range,
      category: category,
      intent: intent,
      currencySymbol: currencySymbol,
      analysisPrompt: 'What do you think of this spending pattern?',
    );
  }

  Future<TherapistScopedResolution> buildBudgetPreviewForMonth({
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
    required DateTime monthDate,
  }) {
    return _buildBudgetResolution(
      monthDate: DateTime(monthDate.year, monthDate.month, 1),
      intent: intent,
      userId: userId,
      profileId: profileId,
      currencySymbol: currencySymbol,
      analysisPrompt: 'What do you think of this budget performance?',
    );
  }

  Future<TherapistScopedResolution> resolveOption({
    required TherapistScopedOption option,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    switch (option.kind) {
      case TherapistScopedDataKind.loan:
        final loan = await _loanService.getLoanById(option.id);
        if (loan == null) {
          return _buildUnavailablePreview(
            kind: option.kind,
            intent: intent,
            title: 'Loan not found',
            subtitle: 'The selected loan is no longer available.',
          );
        }
        return _buildLoanPreview(
          loan,
          intent,
          currencySymbol,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case TherapistScopedDataKind.iou:
        final iou = await _iouService.getIOUById(option.id);
        if (iou == null) {
          return _buildUnavailablePreview(
            kind: option.kind,
            intent: intent,
            title: 'IOU not found',
            subtitle: 'The selected IOU is no longer available.',
          );
        }
        return _buildIOUPreview(
          iou,
          intent,
          currencySymbol,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case TherapistScopedDataKind.receivable:
        final receivable = await _receivableService.getReceivableById(
          option.id,
        );
        if (receivable == null) {
          return _buildUnavailablePreview(
            kind: option.kind,
            intent: intent,
            title: 'Lent record not found',
            subtitle: 'The selected receivable is no longer available.',
          );
        }
        return _buildReceivablePreview(
          receivable,
          intent,
          currencySymbol,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case TherapistScopedDataKind.reimbursement:
        final reimbursement = await _reimbursementService.getReimbursementById(
          option.id,
        );
        if (reimbursement == null) {
          return _buildUnavailablePreview(
            kind: option.kind,
            intent: intent,
            title: 'Reimbursement not found',
            subtitle: 'The selected reimbursement is no longer available.',
          );
        }
        return _buildReimbursementPreview(
          reimbursement,
          intent,
          currencySymbol,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );
      case TherapistScopedDataKind.expenses:
      case TherapistScopedDataKind.budget:
        return _buildUnavailablePreview(
          kind: option.kind,
          intent: intent,
          title: 'Selection not supported',
          subtitle: 'Please retry the request from the therapist.',
        );
    }
  }

  Future<TherapistScopedResolution> _buildResolution({
    required String text,
    required TherapistScopedIntent intent,
    required TherapistScopedDataKind kind,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    switch (kind) {
      case TherapistScopedDataKind.expenses:
        return _buildExpensePreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
      case TherapistScopedDataKind.budget:
        return _buildBudgetPreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
      case TherapistScopedDataKind.loan:
        return _buildLoanPreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
      case TherapistScopedDataKind.iou:
        return _buildIOUPreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
      case TherapistScopedDataKind.receivable:
        return _buildReceivablePreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
      case TherapistScopedDataKind.reimbursement:
        return _buildReimbursementPreviewFromText(
          text: text,
          intent: intent,
          userId: userId,
          profileId: profileId,
          currencySymbol: currencySymbol,
        );
    }
  }

  TherapistScopedIntent? _detectIntent(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('share') ||
        lower.contains('send this') ||
        lower.contains('export')) {
      return TherapistScopedIntent.share;
    }

    if (lower.contains('what do you think') ||
        lower.contains('analy') ||
        lower.contains('how am i doing') ||
        lower.contains('thoughts') ||
        lower.contains('advice') ||
        lower.contains('is this okay')) {
      return TherapistScopedIntent.askAi;
    }

    return null;
  }

  Future<TherapistScopedDataKind?> _detectKind(String text, int userId) async {
    final lower = text.toLowerCase();

    if (lower.contains('budget')) return TherapistScopedDataKind.budget;
    if (lower.contains('loan')) return TherapistScopedDataKind.loan;
    if (lower.contains('iou') || lower.contains('owe')) {
      return TherapistScopedDataKind.iou;
    }
    if (lower.contains('reimbursement')) {
      return TherapistScopedDataKind.reimbursement;
    }
    if (lower.contains('lent') || lower.contains('receivable')) {
      return TherapistScopedDataKind.receivable;
    }
    if (lower.contains('expense') ||
        lower.contains('spending') ||
        lower.contains('spent')) {
      return TherapistScopedDataKind.expenses;
    }

    final categories = await _categoryService.getAllCategories(userId);
    for (final category in categories) {
      final name = category.name.toLowerCase();
      if (name.isNotEmpty && lower.contains(name)) {
        return TherapistScopedDataKind.expenses;
      }
    }

    return null;
  }

  Future<TherapistScopedResolution> _buildExpensePreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final categories = await _categoryService.getAllCategories(userId);
    final range = _resolveExpenseRange(text);
    final category = _detectCategoryFilter(text, categories);
    final transactions = await _fetchExpenseRows(
      userId: userId,
      profileId: profileId,
      start: range.start,
      end: range.end,
      categoryId: category?.categoryId,
    );

    return _buildExpenseResolution(
      transactions: transactions,
      range: range,
      category: category,
      intent: intent,
      currencySymbol: currencySymbol,
      analysisPrompt: text,
    );
  }

  TherapistScopedResolution _buildExpenseResolution({
    required List<_ExpenseRow> transactions,
    required _ResolvedRange range,
    required Category? category,
    required TherapistScopedIntent intent,
    required String currencySymbol,
    required String analysisPrompt,
  }) {
    if (transactions.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.expenses,
        intent: intent,
        title: 'No expenses found',
        subtitle: category == null
            ? range.label
            : '${category.name} • ${range.label}',
      );
    }

    final total = transactions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final byCategory = <String, double>{};
    for (final item in transactions) {
      final name = item.categoryName ?? 'Uncategorized';
      byCategory[name] = (byCategory[name] ?? 0) + item.amount;
    }

    final topCategoryLines = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final title = category == null
        ? 'Expenses for ${range.label}'
        : '${category.name} spending for ${range.label}';
    final subtitle =
        '${transactions.length} transaction${transactions.length == 1 ? '' : 's'} • $currencySymbol${total.toStringAsFixed(2)}';

    final lines = <String>[
      'Top categories:',
      ...topCategoryLines
          .take(4)
          .map(
            (entry) =>
                '- ${entry.key}: $currencySymbol${entry.value.toStringAsFixed(2)}',
          ),
      '',
      'Transactions:',
      ...transactions
          .take(8)
          .expand((item) => _formatExpenseItem(item, currencySymbol)),
    ];

    if (transactions.length > 8) {
      lines.add('...and ${transactions.length - 8} more transaction(s)');
    }

    final body = lines.join('\n');

    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.expenses,
        intent: intent,
        title: title,
        subtitle: subtitle,
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\nScope: ${range.label}\n$body',
        defaultQuestion: category == null
            ? 'What do you think of this spending pattern?'
            : 'What do you think of this ${category.name.toLowerCase()} spending?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
      analysisPrompt: analysisPrompt,
    );
  }

  Future<TherapistScopedResolution> _buildBudgetPreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final monthDate = _resolveBudgetMonth(text);
    return _buildBudgetResolution(
      monthDate: monthDate,
      intent: intent,
      userId: userId,
      profileId: profileId,
      currencySymbol: currencySymbol,
      analysisPrompt: text,
    );
  }

  Future<TherapistScopedResolution> _buildBudgetResolution({
    required DateTime monthDate,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
    required String analysisPrompt,
  }) async {
    final budgets = await _budgetService.getBudgets(
      userId,
      monthDate.month,
      monthDate.year,
      profileId: profileId,
    );
    final spending = await _budgetService.getMonthlySpending(
      userId,
      monthDate.month,
      monthDate.year,
      profileId: profileId,
    );
    final categories = await _categoryService.getAllCategories(userId);
    final categoryMap = {
      for (final category in categories)
        if (category.categoryId != null) category.categoryId!: category,
    };
    final categoryBudgets = budgets
        .where((budget) => budget.categoryId != null)
        .toList();

    if (categoryBudgets.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.budget,
        intent: intent,
        title: 'No budget found',
        subtitle: _monthFormat.format(monthDate),
      );
    }

    final totalBudget = categoryBudgets.fold<double>(
      0,
      (sum, budget) => sum + budget.amount,
    );
    final totalSpent = categoryBudgets.fold<double>(
      0,
      (sum, budget) => sum + (spending[budget.categoryId] ?? 0.0),
    );
    final remaining = totalBudget - totalSpent;

    final lines = <String>[
      'Total budget: $currencySymbol${totalBudget.toStringAsFixed(2)}',
      'Spent: $currencySymbol${totalSpent.toStringAsFixed(2)}',
      'Remaining: $currencySymbol${remaining.toStringAsFixed(2)}',
      '',
      'Category breakdown:',
      ...categoryBudgets.map((budget) {
        final categoryName =
            categoryMap[budget.categoryId]?.name ?? 'Uncategorized';
        final spent = spending[budget.categoryId] ?? 0.0;
        final pct = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
        return '- $categoryName: $currencySymbol${spent.toStringAsFixed(2)} / $currencySymbol${budget.amount.toStringAsFixed(2)} (${pct.toStringAsFixed(0)}% used)';
      }),
    ];

    final title = 'Budget for ${_monthFormat.format(monthDate)}';
    final body = lines.join('\n');

    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.budget,
        intent: intent,
        title: title,
        subtitle:
            '$currencySymbol${remaining.toStringAsFixed(2)} remaining of $currencySymbol${totalBudget.toStringAsFixed(2)}',
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\n$body',
        defaultQuestion: 'What do you think of this budget performance?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
      analysisPrompt: analysisPrompt,
    );
  }

  Future<TherapistScopedResolution> _buildLoanPreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final active = await _loanService.getActiveLoans(
      userId,
      profileId: profileId,
    );
    final completed = await _loanService.getCompletedLoans(
      userId,
      profileId: profileId,
    );
    final all = [...active, ...completed];
    if (all.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.loan,
        intent: intent,
        title: 'No loans found',
        subtitle: 'There are no loans to review right now.',
      );
    }

    final matches = _matchByText<Loan>(text, all, (loan) => loan.lenderName);
    if (matches.length > 1) {
      return TherapistScopedResolution(
        ambiguityMessage:
            'I found multiple loans. Pick the one you want to review.',
        options: matches.take(6).map((loan) {
          final remaining = loan.estimatedTotalPayable > 0
              ? (loan.estimatedTotalPayable - loan.totalPaid)
              : (loan.principalAmount - loan.totalPaid);
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.loan,
            intent: intent,
            id: loan.loanId ?? 0,
            label: loan.lenderName,
            subtitle:
                '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
          );
        }).toList(),
      );
    }

    final selected = matches.isNotEmpty
        ? matches.first
        : all.length == 1
        ? all.first
        : null;
    if (selected == null) {
      return TherapistScopedResolution(
        ambiguityMessage: 'Choose which loan you want to review.',
        options: all.take(6).map((loan) {
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.loan,
            intent: intent,
            id: loan.loanId ?? 0,
            label: loan.lenderName,
            subtitle: loan.status.toUpperCase(),
          );
        }).toList(),
      );
    }

    return _buildLoanPreview(selected, intent, currencySymbol);
  }

  Future<TherapistScopedResolution> _buildLoanPreview(
    Loan loan,
    TherapistScopedIntent intent,
    String currencySymbol, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final payments = _filterPaymentsByRange<LoanPayment>(
      await _loanService.getLoanPayments(loan.loanId!),
      rangeStart,
      rangeEnd,
      (payment) => payment.paymentDate,
    );
    final totalPayable = loan.estimatedTotalPayable > 0
        ? loan.estimatedTotalPayable
        : loan.principalAmount;
    final remaining = totalPayable - loan.totalPaid;
    final rangeLabel = _formatOptionalRangeLabel(rangeStart, rangeEnd);
    final lines = <String>[
      'Principal: $currencySymbol${loan.principalAmount.toStringAsFixed(2)}',
      'Total payable: $currencySymbol${totalPayable.toStringAsFixed(2)}',
      'Paid: $currencySymbol${loan.totalPaid.toStringAsFixed(2)}',
      'Remaining: $currencySymbol${remaining.toStringAsFixed(2)}',
      'Status: ${loan.status}',
      if (rangeLabel != null) 'Selected range: $rangeLabel',
      if (loan.dueDate != null)
        'Due date: ${_dateFormat.format(loan.dueDate!)}',
      if (loan.loanType.isNotEmpty) 'Type: ${loan.loanType}',
      '',
      'Recent payments:',
      ..._formatPaymentLines<LoanPayment>(
        payments,
        currencySymbol,
        (payment) => payment.paymentAmount,
        (payment) => payment.paymentDate,
      ),
    ];

    final title = '${loan.lenderName} loan details';
    final body = lines.join('\n');

    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.loan,
        intent: intent,
        recordId: loan.loanId,
        title: title,
        subtitle: '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\n$body',
        defaultQuestion: 'What do you think of this loan situation?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
    );
  }

  Future<TherapistScopedResolution> _buildIOUPreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final active = await _iouService.getActiveIOUs(
      userId,
      profileId: profileId,
    );
    final completed = await _iouService.getCompletedIOUs(
      userId,
      profileId: profileId,
    );
    final all = [...active, ...completed];
    if (all.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.iou,
        intent: intent,
        title: 'No IOUs found',
        subtitle: 'There are no IOUs to review right now.',
      );
    }

    final matches = _matchByText<IOU>(text, all, (iou) => iou.creditorName);
    if (matches.length > 1) {
      return TherapistScopedResolution(
        ambiguityMessage:
            'I found multiple IOUs. Pick the one you want to review.',
        options: matches.take(6).map((iou) {
          final remaining = iou.estimatedTotalPayable > 0
              ? (iou.estimatedTotalPayable - iou.totalPaid)
              : (iou.amount - iou.totalPaid);
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.iou,
            intent: intent,
            id: iou.iouId ?? 0,
            label: iou.creditorName,
            subtitle:
                '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
          );
        }).toList(),
      );
    }

    final selected = matches.isNotEmpty
        ? matches.first
        : all.length == 1
        ? all.first
        : null;
    if (selected == null) {
      return TherapistScopedResolution(
        ambiguityMessage: 'Choose which IOU you want to review.',
        options: all.take(6).map((iou) {
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.iou,
            intent: intent,
            id: iou.iouId ?? 0,
            label: iou.creditorName,
            subtitle: iou.status.toUpperCase(),
          );
        }).toList(),
      );
    }

    return _buildIOUPreview(selected, intent, currencySymbol);
  }

  Future<TherapistScopedResolution> _buildIOUPreview(
    IOU iou,
    TherapistScopedIntent intent,
    String currencySymbol, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final payments = _filterPaymentsByRange<IOUPayment>(
      await _iouService.getIOUPayments(iou.iouId!),
      rangeStart,
      rangeEnd,
      (payment) => payment.paymentDate,
    );
    final totalPayable = iou.estimatedTotalPayable > 0
        ? iou.estimatedTotalPayable
        : iou.amount;
    final remaining = totalPayable - iou.totalPaid;
    final rangeLabel = _formatOptionalRangeLabel(rangeStart, rangeEnd);
    final lines = <String>[
      'Amount: $currencySymbol${iou.amount.toStringAsFixed(2)}',
      'Total payable: $currencySymbol${totalPayable.toStringAsFixed(2)}',
      'Paid: $currencySymbol${iou.totalPaid.toStringAsFixed(2)}',
      'Remaining: $currencySymbol${remaining.toStringAsFixed(2)}',
      'Status: ${iou.status}',
      if (rangeLabel != null) 'Selected range: $rangeLabel',
      if (iou.dueDate != null) 'Due date: ${_dateFormat.format(iou.dueDate!)}',
      if ((iou.reason ?? '').isNotEmpty) 'Reason: ${iou.reason}',
      '',
      'Recent payments:',
      ..._formatPaymentLines<IOUPayment>(
        payments,
        currencySymbol,
        (payment) => payment.paymentAmount,
        (payment) => payment.paymentDate,
      ),
    ];

    final title = '${iou.creditorName} IOU details';
    final body = lines.join('\n');
    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.iou,
        intent: intent,
        recordId: iou.iouId,
        title: title,
        subtitle: '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\n$body',
        defaultQuestion: 'What do you think of this IOU situation?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
    );
  }

  Future<TherapistScopedResolution> _buildReceivablePreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final active = await _receivableService.getActiveReceivables(
      userId,
      profileId: profileId,
    );
    final completed = await _receivableService.getCompletedReceivables(
      userId,
      profileId: profileId,
    );
    final all = [...active, ...completed];
    if (all.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.receivable,
        intent: intent,
        title: 'No lent records found',
        subtitle: 'There are no receivables to review right now.',
      );
    }

    final matches = _matchByText<Receivable>(
      text,
      all,
      (receivable) => receivable.recipientName,
    );
    if (matches.length > 1) {
      return TherapistScopedResolution(
        ambiguityMessage:
            'I found multiple lent records. Pick the one you want to review.',
        options: matches.take(6).map((receivable) {
          final remaining =
              receivable.principalAmount - receivable.totalReceived;
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.receivable,
            intent: intent,
            id: receivable.receivableId ?? 0,
            label: receivable.recipientName,
            subtitle:
                '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
          );
        }).toList(),
      );
    }

    final selected = matches.isNotEmpty
        ? matches.first
        : all.length == 1
        ? all.first
        : null;
    if (selected == null) {
      return TherapistScopedResolution(
        ambiguityMessage: 'Choose which lent record you want to review.',
        options: all.take(6).map((receivable) {
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.receivable,
            intent: intent,
            id: receivable.receivableId ?? 0,
            label: receivable.recipientName,
            subtitle: receivable.status.toUpperCase(),
          );
        }).toList(),
      );
    }

    return _buildReceivablePreview(selected, intent, currencySymbol);
  }

  Future<TherapistScopedResolution> _buildReceivablePreview(
    Receivable receivable,
    TherapistScopedIntent intent,
    String currencySymbol, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final payments = _filterPaymentsByRange<ReceivablePayment>(
      await _receivableService.getReceivablePayments(receivable.receivableId!),
      rangeStart,
      rangeEnd,
      (payment) => payment.paymentDate,
    );
    final remaining = receivable.principalAmount - receivable.totalReceived;
    final rangeLabel = _formatOptionalRangeLabel(rangeStart, rangeEnd);
    final lines = <String>[
      'Principal: $currencySymbol${receivable.principalAmount.toStringAsFixed(2)}',
      'Received: $currencySymbol${receivable.totalReceived.toStringAsFixed(2)}',
      'Remaining: $currencySymbol${remaining.toStringAsFixed(2)}',
      'Status: ${receivable.status}',
      if (rangeLabel != null) 'Selected range: $rangeLabel',
      if (receivable.expectedDate != null)
        'Expected date: ${_dateFormat.format(receivable.expectedDate!)}',
      if (receivable.receivableType.isNotEmpty)
        'Type: ${receivable.receivableType}',
      '',
      'Recent receipts:',
      ..._formatPaymentLines<ReceivablePayment>(
        payments,
        currencySymbol,
        (payment) => payment.paymentAmount,
        (payment) => payment.paymentDate,
      ),
    ];

    final title = '${receivable.recipientName} lent details';
    final body = lines.join('\n');
    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.receivable,
        intent: intent,
        recordId: receivable.receivableId,
        title: title,
        subtitle: '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\n$body',
        defaultQuestion: 'What do you think of this lent-money situation?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
    );
  }

  Future<TherapistScopedResolution> _buildReimbursementPreviewFromText({
    required String text,
    required TherapistScopedIntent intent,
    required int userId,
    required int profileId,
    required String currencySymbol,
  }) async {
    final active = await _reimbursementService.getActiveReimbursements(
      userId,
      profileId: profileId,
    );
    final completed = await _reimbursementService.getCompletedReimbursements(
      userId,
      profileId: profileId,
    );
    final all = [...active, ...completed];
    if (all.isEmpty) {
      return _buildUnavailablePreview(
        kind: TherapistScopedDataKind.reimbursement,
        intent: intent,
        title: 'No reimbursements found',
        subtitle: 'There are no reimbursements to review right now.',
      );
    }

    final matches = _matchByText<Reimbursement>(
      text,
      all,
      (reimbursement) => reimbursement.sourceName,
    );
    if (matches.length > 1) {
      return TherapistScopedResolution(
        ambiguityMessage:
            'I found multiple reimbursements. Pick the one you want to review.',
        options: matches.take(6).map((reimbursement) {
          final remaining =
              reimbursement.amount - reimbursement.totalReimbursed;
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.reimbursement,
            intent: intent,
            id: reimbursement.reimbursementId ?? 0,
            label: reimbursement.sourceName,
            subtitle:
                '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
          );
        }).toList(),
      );
    }

    final selected = matches.isNotEmpty
        ? matches.first
        : all.length == 1
        ? all.first
        : null;
    if (selected == null) {
      return TherapistScopedResolution(
        ambiguityMessage: 'Choose which reimbursement you want to review.',
        options: all.take(6).map((reimbursement) {
          return TherapistScopedOption(
            kind: TherapistScopedDataKind.reimbursement,
            intent: intent,
            id: reimbursement.reimbursementId ?? 0,
            label: reimbursement.sourceName,
            subtitle: reimbursement.status.toUpperCase(),
          );
        }).toList(),
      );
    }

    return _buildReimbursementPreview(selected, intent, currencySymbol);
  }

  Future<TherapistScopedResolution> _buildReimbursementPreview(
    Reimbursement reimbursement,
    TherapistScopedIntent intent,
    String currencySymbol, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final payments = _filterPaymentsByRange<ReimbursementPayment>(
      await _reimbursementService.getReimbursementPayments(
        reimbursement.reimbursementId!,
      ),
      rangeStart,
      rangeEnd,
      (payment) => payment.paymentDate,
    );
    final remaining = reimbursement.amount - reimbursement.totalReimbursed;
    final rangeLabel = _formatOptionalRangeLabel(rangeStart, rangeEnd);
    final lines = <String>[
      'Amount: $currencySymbol${reimbursement.amount.toStringAsFixed(2)}',
      'Reimbursed: $currencySymbol${reimbursement.totalReimbursed.toStringAsFixed(2)}',
      'Remaining: $currencySymbol${remaining.toStringAsFixed(2)}',
      'Status: ${reimbursement.status}',
      if (rangeLabel != null) 'Selected range: $rangeLabel',
      if (reimbursement.expectedDate != null)
        'Expected date: ${_dateFormat.format(reimbursement.expectedDate!)}',
      if ((reimbursement.category ?? '').isNotEmpty)
        'Category: ${reimbursement.category}',
      '',
      'Recent reimbursements:',
      ..._formatPaymentLines<ReimbursementPayment>(
        payments,
        currencySymbol,
        (payment) => payment.paymentAmount,
        (payment) => payment.paymentDate,
      ),
    ];

    final title = '${reimbursement.sourceName} reimbursement details';
    final body = lines.join('\n');
    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: TherapistScopedDataKind.reimbursement,
        intent: intent,
        recordId: reimbursement.reimbursementId,
        title: title,
        subtitle: '$currencySymbol${remaining.toStringAsFixed(2)} remaining',
        body: body,
        shareText: '$title\n$body',
        aiContext: 'Selected dataset: $title\n$body',
        defaultQuestion: 'What do you think of this reimbursement situation?',
      ),
      shouldAutoAnalyze: intent == TherapistScopedIntent.askAi,
    );
  }

  TherapistScopedResolution _buildUnavailablePreview({
    required TherapistScopedDataKind kind,
    required TherapistScopedIntent intent,
    required String title,
    required String subtitle,
  }) {
    final body = '$title\n$subtitle';
    return TherapistScopedResolution(
      preview: TherapistScopedPreview(
        kind: kind,
        intent: intent,
        title: title,
        subtitle: subtitle,
        body: body,
        shareText: body,
        aiContext: body,
        defaultQuestion: 'What do you think of this?',
        actionsEnabled: false,
      ),
    );
  }

  _ResolvedRange _resolveExpenseRange(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();

    if (lower.contains('last 7 days') || lower.contains('last week')) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      final end = DateTime(now.year, now.month, now.day);
      return _ResolvedRange(start: start, end: end, label: 'Last 7 Days');
    }

    if (lower.contains('last month')) {
      final month = DateTime(now.year, now.month - 1, 1);
      return _ResolvedRange(
        start: month,
        end: DateTime(month.year, month.month + 1, 0),
        label: _monthFormat.format(month),
      );
    }

    if (lower.contains('this month')) {
      final month = DateTime(now.year, now.month, 1);
      return _ResolvedRange(
        start: month,
        end: DateTime(now.year, now.month, now.day),
        label: _monthFormat.format(month),
      );
    }

    final monthMatch = _tryParseNamedMonth(lower);
    if (monthMatch != null) {
      return _ResolvedRange(
        start: DateTime(monthMatch.year, monthMatch.month, 1),
        end: DateTime(monthMatch.year, monthMatch.month + 1, 0),
        label: _monthFormat.format(monthMatch),
      );
    }

    final defaultStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final defaultEnd = DateTime(now.year, now.month, now.day);
    return _ResolvedRange(
      start: defaultStart,
      end: defaultEnd,
      label: 'Last 7 Days',
    );
  }

  DateTime _resolveBudgetMonth(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    if (lower.contains('last month')) {
      return DateTime(now.year, now.month - 1, 1);
    }
    if (lower.contains('this month')) {
      return DateTime(now.year, now.month, 1);
    }
    return _tryParseNamedMonth(lower) ?? DateTime(now.year, now.month, 1);
  }

  DateTime? _tryParseNamedMonth(String lower) {
    const monthNames = <String, int>{
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };

    for (final entry in monthNames.entries) {
      if (lower.contains(entry.key)) {
        final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(lower);
        final year = yearMatch != null
            ? int.parse(yearMatch.group(1)!)
            : DateTime.now().year;
        return DateTime(year, entry.value, 1);
      }
    }
    return null;
  }

  Category? _detectCategoryFilter(String text, List<Category> categories) {
    final lower = text.toLowerCase();
    Category? best;
    for (final category in categories) {
      final name = category.name.toLowerCase();
      if (name.isNotEmpty && lower.contains(name)) {
        if (best == null || name.length > best.name.length) {
          best = category;
        }
      }
    }
    return best;
  }

  List<T> _matchByText<T>(
    String text,
    List<T> items,
    String Function(T item) selector,
  ) {
    final lower = text.toLowerCase();
    return items.where((item) {
      final candidate = selector(item).trim().toLowerCase();
      return candidate.isNotEmpty && lower.contains(candidate);
    }).toList();
  }

  Future<List<_ExpenseRow>> _fetchExpenseRows({
    required int userId,
    required int profileId,
    required DateTime start,
    required DateTime end,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    final args = <dynamic>[
      userId,
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
      profileId,
      if (categoryId != null) categoryId,
    ];

    final categoryClause = categoryId != null ? ' AND t.category_id = ?' : '';
    final transactionRows = await db.rawQuery('''
      SELECT
        t.transaction_id,
        t.amount,
        t.transaction_date,
        t.note,
        t.is_split,
        c.name as category_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.category_id
      WHERE t.user_id = ?
        AND date(t.transaction_date) >= ?
        AND date(t.transaction_date) <= ?
        AND t.parent_transaction_id IS NULL
        AND t.profile_id = ?$categoryClause
      ORDER BY date(t.transaction_date) DESC, t.created_at DESC
      ''', args);

    final transactionIds = transactionRows
        .map((row) => row['transaction_id'] as int)
        .toList();
    final splitByTransaction = <int, List<_SplitExpenseRow>>{};

    if (transactionIds.isNotEmpty) {
      final splitRows = await db.rawQuery('''
        SELECT
          si.transaction_id,
          si.name,
          si.amount,
          c.name as category_name
        FROM split_items si
        LEFT JOIN categories c ON si.category_id = c.category_id
        WHERE si.transaction_id IN (${transactionIds.join(',')})
        ORDER BY si.transaction_id, si.created_at ASC
        ''');

      for (final row in splitRows) {
        final transactionId = row['transaction_id'] as int;
        splitByTransaction.putIfAbsent(transactionId, () => []);
        splitByTransaction[transactionId]!.add(
          _SplitExpenseRow(
            name: row['name'] as String,
            amount: (row['amount'] as num).toDouble(),
            categoryName: row['category_name'] as String?,
          ),
        );
      }
    }

    return transactionRows.map((row) {
      final id = row['transaction_id'] as int;
      return _ExpenseRow(
        transactionId: id,
        amount: (row['amount'] as num).toDouble(),
        date: DateTime.parse(row['transaction_date'] as String),
        note: row['note'] as String?,
        categoryName: row['category_name'] as String?,
        splitItems: splitByTransaction[id] ?? const [],
      );
    }).toList();
  }

  List<String> _formatExpenseItem(_ExpenseRow row, String currencySymbol) {
    final title = row.note?.trim().isNotEmpty == true
        ? row.note!.trim()
        : (row.categoryName ?? 'Expense');
    final lines = <String>[
      '- ${_dateFormat.format(row.date)}: $title • $currencySymbol${row.amount.toStringAsFixed(2)}',
    ];
    for (final split in row.splitItems) {
      final splitLabel = split.categoryName?.isNotEmpty == true
          ? ' (${split.categoryName})'
          : '';
      lines.add(
        '  • ${split.name}$splitLabel: $currencySymbol${split.amount.toStringAsFixed(2)}',
      );
    }
    return lines;
  }

  List<String> _formatPaymentLines<T>(
    List<T> payments,
    String currencySymbol,
    double Function(T payment) amountSelector,
    DateTime Function(T payment) dateSelector,
  ) {
    if (payments.isEmpty) {
      return ['- No payments recorded yet'];
    }

    return payments.take(5).map((payment) {
      final amount = amountSelector(payment);
      final date = dateSelector(payment);
      return '- ${_dateFormat.format(date)}: $currencySymbol${amount.toStringAsFixed(2)}';
    }).toList();
  }

  List<T> _filterPaymentsByRange<T>(
    List<T> payments,
    DateTime? start,
    DateTime? end,
    DateTime Function(T payment) dateSelector,
  ) {
    if (start == null || end == null) return payments;

    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return payments.where((payment) {
      final date = dateSelector(payment);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      return !normalizedDate.isBefore(normalizedStart) &&
          !normalizedDate.isAfter(normalizedEnd);
    }).toList();
  }

  String _formatRangeLabel(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    if (normalizedStart == normalizedEnd) {
      return _dateFormat.format(normalizedStart);
    }
    return '${_dateFormat.format(normalizedStart)} - ${_dateFormat.format(normalizedEnd)}';
  }

  String? _formatOptionalRangeLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    return _formatRangeLabel(start, end);
  }
}

class _ResolvedRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const _ResolvedRange({
    required this.start,
    required this.end,
    required this.label,
  });
}

class _ExpenseRow {
  final int transactionId;
  final double amount;
  final DateTime date;
  final String? note;
  final String? categoryName;
  final List<_SplitExpenseRow> splitItems;

  const _ExpenseRow({
    required this.transactionId,
    required this.amount,
    required this.date,
    this.note,
    this.categoryName,
    this.splitItems = const [],
  });
}

class _SplitExpenseRow {
  final String name;
  final double amount;
  final String? categoryName;

  const _SplitExpenseRow({
    required this.name,
    required this.amount,
    this.categoryName,
  });
}
