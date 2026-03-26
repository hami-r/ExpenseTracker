import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/services/ai_service.dart';
import '../database/services/analytics_service.dart';
import '../database/services/iou_service.dart';
import '../database/services/loan_service.dart';
import '../database/services/receivable_service.dart';
import '../database/services/reimbursement_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../database/database_helper.dart';
import '../models/therapist_scoped_preview.dart';
import '../models/iou.dart';
import '../models/loan.dart';
import '../models/receivable.dart';
import '../models/reimbursement.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../services/financial_therapist_scope_service.dart';
import '../widgets/custom_date_picker.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────
class FinancialTherapistScreen extends StatefulWidget {
  const FinancialTherapistScreen({super.key});

  @override
  State<FinancialTherapistScreen> createState() =>
      _FinancialTherapistScreenState();
}

class _FinancialTherapistScreenState extends State<FinancialTherapistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _userService = UserService();
  final _analyticsService = AnalyticsService();
  final _transactionService = TransactionService();
  final _categoryService = CategoryService();
  final _loanService = LoanService();
  final _iouService = IOUService();
  final _receivableService = ReceivableService();
  final _reimbursementService = ReimbursementService();
  final _scopeService = FinancialTherapistScopeService();
  late final AIService _aiService;

  bool _isLoading = true;
  bool _isTyping = false;
  late DateTime _quickActionFromDate;
  late DateTime _quickActionToDate;

  // Quick reply suggestions
  final List<String> _suggestions = [];

  late final List<_TherapistQuickAction> _quickActions = [
    _TherapistQuickAction(
      label: 'Expenses',
      subtitle: 'Preview a date range, then share or ask AI',
      kind: TherapistScopedDataKind.expenses,
    ),
    _TherapistQuickAction(
      label: 'Budget',
      subtitle: 'Review a month budget, then share or ask AI',
      kind: TherapistScopedDataKind.budget,
    ),
    _TherapistQuickAction(
      label: 'Loan',
      subtitle: 'Open a loan preview for sharing or analysis',
      kind: TherapistScopedDataKind.loan,
    ),
    _TherapistQuickAction(
      label: 'IOU',
      subtitle: 'Open an IOU preview for sharing or analysis',
      kind: TherapistScopedDataKind.iou,
    ),
    _TherapistQuickAction(
      label: 'Lent',
      subtitle: 'Open a lent-money preview for sharing or analysis',
      kind: TherapistScopedDataKind.receivable,
    ),
    _TherapistQuickAction(
      label: 'Reimbursement',
      subtitle: 'Open a reimbursement preview for sharing or analysis',
      kind: TherapistScopedDataKind.reimbursement,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _quickActionFromDate = DateTime(now.year, now.month, 1);
    _quickActionToDate = DateTime(now.year, now.month, now.day);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _aiService = AIService(_categoryService, PaymentMethodService());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.isEmpty) {
        _loadContextAndGreet();
      } else {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContextAndGreet() async {
    // Capture context-dependent values before any async gap
    final profileId = context.read<ProfileProvider>().activeProfileId;
    final currencySymbol = context.read<ProfileProvider>().currencySymbol;

    final user = await _userService.getCurrentUser();
    if (user == null || user.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    try {
      // Fetch all context in parallel
      final results = await Future.wait([
        _analyticsService.getTotalSpending(
          user.userId!,
          startOfMonth,
          endOfMonth,
          profileId: profileId,
        ),
        _analyticsService.getTotalSpending(
          user.userId!,
          sevenDaysAgo,
          now,
          profileId: profileId,
        ),
        _analyticsService.getTopCategories(
          user.userId!,
          startOfMonth,
          endOfMonth,
          5,
          profileId: profileId,
        ),
        _transactionService.getRecentTransactions(
          user.userId!,
          10,
          profileId: profileId,
        ),
        _analyticsService.getTotalBalance(user.userId!, profileId: profileId),
      ]);

      final monthSpend = results[0] as double;
      final weekSpend = results[1] as double;
      final topCategories = results[2] as List<CategorySpending>;
      final recentTx = results[3];
      final balance = results[4] as double;
      final expenseShareSuggestion = _buildExpenseShareSuggestion(
        recentTx as List<dynamic>,
        now,
      );

      final dynamicSuggestions = <String>[
        if (topCategories.isNotEmpty)
          'What do you think of my ${topCategories.first.category.name.toLowerCase()} spending this month?',
        expenseShareSuggestion,
        'Where am I overspending this month?',
        'Share my ${DateFormat('MMMM').format(now)} budget',
      ];

      // Build the financial context string for Gemini
      final categoryLines = topCategories
          .map(
            (c) =>
                '  - ${c.category.name}: $currencySymbol${c.amount.toStringAsFixed(0)}',
          )
          .join('\n');

      // Get budgets from DB directly
      final db = await DatabaseHelper.instance.database;
      final budgetRows = await db.rawQuery(
        '''SELECT b.amount as budget_limit, c.name as cat_name,
           COALESCE(SUM(t.amount),0) as spent
           FROM budgets b
           LEFT JOIN categories c ON b.category_id = c.category_id
           LEFT JOIN transactions t ON t.category_id = b.category_id
             AND t.user_id = b.user_id
             AND strftime('%Y-%m', t.transaction_date) = ?
           WHERE b.user_id = ? AND b.month = ? AND b.year = ?
             AND b.profile_id = ?
           GROUP BY b.budget_id''',
        [
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
          user.userId,
          now.month,
          now.year,
          profileId,
        ],
      );

      final budgetLines = budgetRows.isEmpty
          ? '  - No budgets set'
          : budgetRows
                .map((r) {
                  final limit = (r['budget_limit'] as num).toDouble();
                  final spent = (r['spent'] as num).toDouble();
                  final pct = limit > 0
                      ? (spent / limit * 100).toStringAsFixed(0)
                      : '?';
                  return '  - ${r['cat_name']}: $currencySymbol${spent.toStringAsFixed(0)} / $currencySymbol${limit.toStringAsFixed(0)} ($pct% used)';
                })
                .join('\n');

      final financialContext =
          '''
Net Balance: $currencySymbol${balance.toStringAsFixed(2)}
This Month's Total Spending: $currencySymbol${monthSpend.toStringAsFixed(2)}
Last 7 Days Spending: $currencySymbol${weekSpend.toStringAsFixed(2)}

Top Spending Categories This Month:
$categoryLines

Budget Status:
$budgetLines

Recent Transactions (last 10):
${(recentTx as dynamic).map((t) => '  - ${t.note ?? 'Expense'}: $currencySymbol${t.amount.toStringAsFixed(2)} on ${t.transactionDate}').join('\n')}
''';

      if (!mounted) return;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.setContext(
        financialContext: financialContext,
        userId: user.userId!,
        profileId: profileId,
      );

      setState(() {
        _suggestions
          ..clear()
          ..addAll(dynamicSuggestions);
        _isLoading = false;
      });

      // Proactive greeting — send an initial message from the AI
      await _sendInitialGreeting();
    } catch (e) {
      debugPrint('Error loading financial context: $e');
      setState(() => _isLoading = false);
      _addAIMessage(
        "Hey! I'm your Financial Therapist. I had trouble loading your data — please check your connection and try again 😊",
      );
    }
  }

  Future<void> _sendInitialGreeting() async {
    setState(() => _isTyping = true);
    final chatProvider = context.read<ChatProvider>();
    try {
      final reply = await _aiService.chatWithContext(
        history: [],
        userMessage:
            'Give me a short, friendly, proactive greeting based on my financial data. '
            'Mention one specific insight (like a category where I spent a lot or how my week looks). '
            'Keep it to 2-3 sentences.',
        financialContext: chatProvider.financialContext,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
      );
      if (mounted) _addAIMessage(reply);
    } catch (_) {
      if (mounted) {
        _addAIMessage(
          "Hey! I'm your Financial Therapist 👋 Ask me anything about your spending, budgets, or savings — I have your data loaded and ready!",
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _addAIMessage(String text) {
    if (mounted) {
      _addMessage(ChatMessage(role: MessageRole.model, text: text));
    }
  }

  void _addMessage(ChatMessage message) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addMessage(message);
    chatProvider.addHistory({
      'role': message.role == MessageRole.user ? 'user' : 'model',
      'text': message.text,
    });
    _scrollToBottom();
  }

  String _buildExpenseShareSuggestion(List<dynamic> recentTx, DateTime now) {
    if (recentTx.isEmpty) {
      return 'Share my ${DateFormat('MMMM').format(now)} expenses';
    }

    final latestDate = recentTx
        .map((tx) => tx.transactionDate as DateTime)
        .reduce(
          (latest, current) => current.isAfter(latest) ? current : latest,
        );

    final monthLabel = latestDate.year == now.year
        ? DateFormat('MMMM').format(latestDate)
        : DateFormat('MMMM yyyy').format(latestDate);

    return 'Share my $monthLabel expenses';
  }

  void _addScopedMessage({
    required String text,
    TherapistScopedPreview? preview,
    List<TherapistScopedOption> options = const [],
  }) {
    _addMessage(
      ChatMessage(
        role: MessageRole.model,
        text: text,
        scopedPreview: preview,
        scopedOptions: options,
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final chatProvider = context.read<ChatProvider>();
    _inputController.clear();
    _addMessage(ChatMessage(role: MessageRole.user, text: trimmed));

    setState(() => _isTyping = true);

    try {
      final handled = await _handleScopedRequest(trimmed);
      if (handled) return;

      final reply = await _aiService.chatWithContext(
        history: chatProvider.geminiHistory,
        userMessage: trimmed,
        financialContext: chatProvider.financialContext,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
      );
      if (mounted) _addAIMessage(reply);
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        _addAIMessage(
          "I'm sorry, I'm having trouble thinking right now. Could you repeat that? 🧐",
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<bool> _handleScopedRequest(String text) async {
    final chatProvider = context.read<ChatProvider>();
    final resolution = await _scopeService.resolveTextRequest(
      text: text,
      userId: chatProvider.userId!,
      profileId: chatProvider.profileId!,
      currencySymbol: context.read<ProfileProvider>().currencySymbol,
    );

    if (resolution == null) return false;

    if (resolution.isAmbiguous) {
      _addScopedMessage(
        text: resolution.ambiguityMessage!,
        options: resolution.options,
      );
      return true;
    }

    final preview = resolution.preview;
    if (preview == null) return false;

    _addScopedMessage(
      text: preview.intent == TherapistScopedIntent.share
          ? 'I pulled the exact data below. You can share it or ask me to analyze it.'
          : 'I pulled the exact data below. I’ll analyze this specific slice for you.',
      preview: preview,
    );

    if (resolution.shouldAutoAnalyze) {
      await _askAiAboutPreview(
        preview,
        userQuestion: resolution.analysisPrompt ?? text,
      );
    }

    return true;
  }

  Future<void> _handleQuickAction(_TherapistQuickAction action) async {
    final selectedFrom = DateTime(
      _quickActionFromDate.year,
      _quickActionFromDate.month,
      _quickActionFromDate.day,
    );
    final selectedTo = DateTime(
      _quickActionToDate.year,
      _quickActionToDate.month,
      _quickActionToDate.day,
    );

    switch (action.kind) {
      case TherapistScopedDataKind.expenses:
        await _buildQuickActionExpensePreview(selectedFrom, selectedTo);
        break;
      case TherapistScopedDataKind.budget:
        await _buildQuickActionBudgetPreview(selectedFrom);
        break;
      case TherapistScopedDataKind.loan:
        await _showRecordQuickActionSheet<Loan>(
          kind: TherapistScopedDataKind.loan,
          title: 'Choose Loan',
          subtitle:
              'Loan details with payment activity from ${_formatQuickActionDate(selectedFrom)} to ${_formatQuickActionDate(selectedTo)}.',
          emptyTitle: 'No loans found',
          emptySubtitle:
              'Create a loan first, then you can share or analyze it.',
          rangeStart: selectedFrom,
          rangeEnd: selectedTo,
          loadRecords: (userId, profileId) async {
            final active = await _loanService.getActiveLoans(
              userId,
              profileId: profileId,
            );
            final completed = await _loanService.getCompletedLoans(
              userId,
              profileId: profileId,
            );
            return [...active, ...completed];
          },
          toOption: (loan) => TherapistScopedOption(
            kind: TherapistScopedDataKind.loan,
            intent: TherapistScopedIntent.share,
            id: loan.loanId!,
            label: loan.lenderName,
            subtitle:
                '${_formatMoney(loan.principalAmount)} • ${_capitalizeStatus(loan.status)}',
          ),
        );
        break;
      case TherapistScopedDataKind.iou:
        await _showRecordQuickActionSheet<IOU>(
          kind: TherapistScopedDataKind.iou,
          title: 'Choose IOU',
          subtitle:
              'IOU details with payment activity from ${_formatQuickActionDate(selectedFrom)} to ${_formatQuickActionDate(selectedTo)}.',
          emptyTitle: 'No IOUs found',
          emptySubtitle:
              'Create an IOU first, then you can share or analyze it.',
          rangeStart: selectedFrom,
          rangeEnd: selectedTo,
          loadRecords: (userId, profileId) async {
            final active = await _iouService.getActiveIOUs(
              userId,
              profileId: profileId,
            );
            final completed = await _iouService.getCompletedIOUs(
              userId,
              profileId: profileId,
            );
            return [...active, ...completed];
          },
          toOption: (iou) => TherapistScopedOption(
            kind: TherapistScopedDataKind.iou,
            intent: TherapistScopedIntent.share,
            id: iou.iouId!,
            label: iou.creditorName,
            subtitle:
                '${_formatMoney(iou.amount)} • ${_capitalizeStatus(iou.status)}',
          ),
        );
        break;
      case TherapistScopedDataKind.receivable:
        await _showRecordQuickActionSheet<Receivable>(
          kind: TherapistScopedDataKind.receivable,
          title: 'Choose Lent Record',
          subtitle:
              'Lent details with receipts from ${_formatQuickActionDate(selectedFrom)} to ${_formatQuickActionDate(selectedTo)}.',
          emptyTitle: 'No lent records found',
          emptySubtitle:
              'Create a lent record first, then you can share or analyze it.',
          rangeStart: selectedFrom,
          rangeEnd: selectedTo,
          loadRecords: (userId, profileId) async {
            final active = await _receivableService.getActiveReceivables(
              userId,
              profileId: profileId,
            );
            final completed = await _receivableService.getCompletedReceivables(
              userId,
              profileId: profileId,
            );
            return [...active, ...completed];
          },
          toOption: (receivable) => TherapistScopedOption(
            kind: TherapistScopedDataKind.receivable,
            intent: TherapistScopedIntent.share,
            id: receivable.receivableId!,
            label: receivable.recipientName,
            subtitle:
                '${_formatMoney(receivable.principalAmount)} • ${_capitalizeStatus(receivable.status)}',
          ),
        );
        break;
      case TherapistScopedDataKind.reimbursement:
        await _showRecordQuickActionSheet<Reimbursement>(
          kind: TherapistScopedDataKind.reimbursement,
          title: 'Choose Reimbursement',
          subtitle:
              'Reimbursements from ${_formatQuickActionDate(selectedFrom)} to ${_formatQuickActionDate(selectedTo)}.',
          emptyTitle: 'No reimbursements found',
          emptySubtitle:
              'Create a reimbursement first, then you can share or analyze it.',
          rangeStart: selectedFrom,
          rangeEnd: selectedTo,
          loadRecords: (userId, profileId) async {
            final active = await _reimbursementService.getActiveReimbursements(
              userId,
              profileId: profileId,
            );
            final completed = await _reimbursementService
                .getCompletedReimbursements(userId, profileId: profileId);
            return [...active, ...completed];
          },
          toOption: (reimbursement) => TherapistScopedOption(
            kind: TherapistScopedDataKind.reimbursement,
            intent: TherapistScopedIntent.share,
            id: reimbursement.reimbursementId!,
            label: reimbursement.sourceName,
            subtitle:
                '${_formatMoney(reimbursement.amount)} • ${_capitalizeStatus(reimbursement.status)}',
          ),
        );
        break;
    }
  }

  Future<void> _showRecordQuickActionSheet<T>({
    required TherapistScopedDataKind kind,
    required String title,
    required String subtitle,
    required String emptyTitle,
    required String emptySubtitle,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Future<List<T>> Function(int userId, int profileId) loadRecords,
    required TherapistScopedOption Function(T record) toOption,
  }) async {
    final chatProvider = context.read<ChatProvider>();
    final records = await loadRecords(
      chatProvider.userId!,
      chatProvider.profileId!,
    );

    if (!mounted) return;

    if (records.isEmpty) {
      _addScopedMessage(
        text: emptySubtitle,
        preview: TherapistScopedPreview(
          kind: kind,
          intent: TherapistScopedIntent.share,
          title: emptyTitle,
          subtitle: emptySubtitle,
          body: emptySubtitle,
          shareText: emptySubtitle,
          aiContext: emptySubtitle,
          defaultQuestion: 'What should I do next?',
          actionsEnabled: false,
        ),
      );
      return;
    }

    await _showQuickActionOptionsSheet(
      title: title,
      subtitle: subtitle,
      options: records.map((record) {
        final option = toOption(record);
        return _QuickActionChoice(
          label: option.label,
          subtitle: option.subtitle ?? '',
          onTap: () => _handleScopedOptionTap(
            option,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showQuickActionOptionsSheet({
    required String title,
    required String subtitle,
    required List<_QuickActionChoice> options,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.68;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: maxSheetHeight,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1c3326) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                Navigator.pop(context);
                                await option.onTap();
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : primary.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (option.subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              option.subtitle,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark
                                          ? Colors.white38
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _buildQuickActionExpensePreview(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final chatProvider = context.read<ChatProvider>();
    setState(() => _isTyping = true);
    try {
      final resolution = await _scopeService.buildExpensePreviewForRange(
        intent: TherapistScopedIntent.share,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
        currencySymbol: context.read<ProfileProvider>().currencySymbol,
        start: fromDate,
        end: toDate,
      );

      if (resolution.isAmbiguous) {
        _addScopedMessage(
          text: resolution.ambiguityMessage!,
          options: resolution.options,
        );
        return;
      }

      final preview = resolution.preview;
      if (preview == null) return;

      _addScopedMessage(
        text:
            'Here’s the prepared dataset. You can share it or ask me about it.',
        preview: preview,
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _buildQuickActionBudgetPreview(DateTime fromDate) async {
    final chatProvider = context.read<ChatProvider>();
    setState(() => _isTyping = true);
    try {
      final resolution = await _scopeService.buildBudgetPreviewForMonth(
        intent: TherapistScopedIntent.share,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
        currencySymbol: context.read<ProfileProvider>().currencySymbol,
        monthDate: fromDate,
      );

      final preview = resolution.preview;
      if (preview == null) return;

      _addScopedMessage(
        text:
            'Here’s the prepared dataset. You can share it or ask me about it.',
        preview: preview,
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  String _formatMoney(double amount) {
    return '${context.read<ProfileProvider>().currencySymbol}${amount.toStringAsFixed(0)}';
  }

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }

  Future<void> _handleScopedOptionTap(
    TherapistScopedOption option, {
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final chatProvider = context.read<ChatProvider>();
    setState(() => _isTyping = true);
    try {
      final resolution = await _scopeService.resolveOption(
        option: option,
        intent: option.intent,
        userId: chatProvider.userId!,
        profileId: chatProvider.profileId!,
        currencySymbol: context.read<ProfileProvider>().currencySymbol,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      final preview = resolution.preview;
      if (preview == null) return;

      _addScopedMessage(
        text: option.intent == TherapistScopedIntent.share
            ? 'I resolved your selection below. You can share it or ask me about it.'
            : 'I resolved your selection below. I’ll analyze this exact data next.',
        preview: preview,
      );

      if (resolution.shouldAutoAnalyze) {
        await _askAiAboutPreview(preview);
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _sharePreview(TherapistScopedPreview preview) async {
    await SharePlus.instance.share(ShareParams(text: preview.shareText));
  }

  Future<void> _askAiAboutPreview(
    TherapistScopedPreview preview, {
    String? userQuestion,
  }) async {
    final chatProvider = context.read<ChatProvider>();
    final prompt = _normalizeScopedQuestion(
      userQuestion?.trim(),
      preview.defaultQuestion,
    );
    final reply = await _aiService.chatWithScopedContext(
      scopedContext: preview.aiContext,
      userMessage: prompt,
      userId: chatProvider.userId!,
      profileId: chatProvider.profileId!,
    );
    if (mounted) {
      _addAIMessage(reply);
    }
  }

  String _normalizeScopedQuestion(String? value, String fallback) {
    if (value == null || value.isEmpty) return fallback;
    final lower = value.toLowerCase();
    if (lower.contains('share')) {
      return fallback;
    }
    return value;
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat?'),
        content: const Text(
          'This will clear the current conversation and start fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(context);
              _loadContextAndGreet();
            },
            child: const Text(
              'New Chat',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, primaryColor),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState(primaryColor)
                      : _buildMessageList(isDark, primaryColor),
                ),
                _buildInputBar(isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 28,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          // AI Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [primary, primary.withValues(alpha: 0.5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF102217),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Therapist',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Always here for you',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : Colors.black87,
              size: 24,
            ),
            tooltip: 'New Chat',
            onPressed: _resetChat,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primary, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(
            'Loading your financial data...',
            style: TextStyle(
              color: primary.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark, Color primary) {
    final chatProvider = context.watch<ChatProvider>();
    final messages = chatProvider.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator bubble
        if (index == messages.length) {
          return _buildTypingIndicator(isDark, primary);
        }
        final msg = messages[index];
        final isUser = msg.role == MessageRole.user;

        // Date separator
        final showDate =
            index == 0 ||
            !_isSameDay(messages[index - 1].timestamp, msg.timestamp);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(msg.timestamp, isDark),
            isUser
                ? _buildUserBubble(msg, isDark, primary)
                : _buildAIBubble(msg, isDark, primary, index),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final label = DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage msg, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('h:mm a').format(msg.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.done_all_rounded,
                size: 14,
                color: primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Read',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(
    ChatMessage msg,
    bool isDark,
    Color primary,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('h:mm a').format(msg.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                      .withValues(alpha: 0.75),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (msg.scopedPreview != null)
            _buildScopedPreviewCard(msg.scopedPreview!, isDark, primary),
          if (msg.scopedOptions.isNotEmpty)
            _buildScopedOptions(msg.scopedOptions, isDark, primary),
          if (index == context.read<ChatProvider>().messages.length - 1 &&
              !_isTyping)
            _buildSuggestions(primary, isDark),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                  .withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(primary, 0),
                const SizedBox(width: 4),
                _buildDot(primary, 150),
                const SizedBox(width: 4),
                _buildDot(primary, 300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Color color, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Use the controller value to drive a sine wave for each dot with an offset
        final progress = (_animationController.value + (index * 0.2)) % 1.0;

        // Sine wave jump: smooth and cute
        final sinVal = math.sin(progress * 2 * math.pi);
        final yOffset = -6.0 * (sinVal > 0 ? sinVal : 0);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: 0.4 + 0.6 * (sinVal > 0 ? sinVal : 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildSuggestions(Color primary, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => _sendMessage(s),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? primary : primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScopedPreviewCard(
    TherapistScopedPreview preview,
    bool isDark,
    Color primary,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF13271d) : Colors.white).withValues(
          alpha: 0.9,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preview.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            preview.body,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: preview.actionsEnabled
                      ? () => _sharePreview(preview)
                      : null,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: preview.actionsEnabled
                      ? () => _askAiAboutPreview(preview)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: const Color(0xFF102217),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Ask AI'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScopedOptions(
    List<TherapistScopedOption> options,
    bool isDark,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          return ActionChip(
            onPressed: () => _handleScopedOptionTap(option),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.18),
            ),
            label: Text(
              option.subtitle == null
                  ? option.label
                  : '${option.label} • ${option.subtitle}',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color primary) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1c3326) : Colors.white).withValues(
              alpha: 0.8,
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showQuickActionsSheet,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      Icons.add_chart_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask your financial therapist...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Send button
              GestureDetector(
                onTap: () => _sendMessage(_inputController.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.72;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: maxSheetHeight,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1c3326) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a date range first, then pick what you want to review.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionDateField(
                                label: 'From',
                                value: _quickActionFromDate,
                                isDark: isDark,
                                primary: primary,
                                onTap: () => _pickQuickActionDate(
                                  initialDate: _quickActionFromDate,
                                  onSelected: (picked) {
                                    setModalState(() {
                                      _quickActionFromDate = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                      );
                                      if (_quickActionFromDate.isAfter(
                                        _quickActionToDate,
                                      )) {
                                        _quickActionToDate =
                                            _quickActionFromDate;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickActionDateField(
                                label: 'To',
                                value: _quickActionToDate,
                                isDark: isDark,
                                primary: primary,
                                onTap: () => _pickQuickActionDate(
                                  initialDate: _quickActionToDate,
                                  onSelected: (picked) {
                                    setModalState(() {
                                      _quickActionToDate = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                      );
                                      if (_quickActionToDate.isBefore(
                                        _quickActionFromDate,
                                      )) {
                                        _quickActionFromDate =
                                            _quickActionToDate;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_formatQuickActionDate(_quickActionFromDate)} to ${_formatQuickActionDate(_quickActionToDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _quickActions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final action = _quickActions[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _handleQuickAction(action);
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : primary.withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: primary.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _iconForQuickAction(action.kind),
                                            color: primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                action.label,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                action.subtitle,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: isDark
                                              ? Colors.white38
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionDateField({
    required String label,
    required DateTime value,
    required bool isDark,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : primary.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatQuickActionDate(value),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickQuickActionDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    CustomDatePicker.show(
      context,
      initialDate: initialDate,
      onDateSelected: onSelected,
    );
  }

  String _formatQuickActionDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  IconData _iconForQuickAction(TherapistScopedDataKind kind) {
    switch (kind) {
      case TherapistScopedDataKind.expenses:
        return Icons.receipt_long_rounded;
      case TherapistScopedDataKind.budget:
        return Icons.account_balance_wallet_rounded;
      case TherapistScopedDataKind.loan:
        return Icons.account_balance_rounded;
      case TherapistScopedDataKind.iou:
        return Icons.handshake_rounded;
      case TherapistScopedDataKind.receivable:
        return Icons.call_received_rounded;
      case TherapistScopedDataKind.reimbursement:
        return Icons.payments_rounded;
    }
  }
}

class _TherapistQuickAction {
  final String label;
  final String subtitle;
  final TherapistScopedDataKind kind;

  const _TherapistQuickAction({
    required this.label,
    required this.subtitle,
    required this.kind,
  });
}

class _QuickActionChoice {
  final String label;
  final String subtitle;
  final Future<void> Function() onTap;

  const _QuickActionChoice({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}
