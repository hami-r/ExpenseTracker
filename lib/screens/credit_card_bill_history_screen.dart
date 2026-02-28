import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/services/credit_card_bill_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../models/payment_method.dart';
import '../providers/profile_provider.dart';

class CreditCardBillHistoryScreen extends StatefulWidget {
  const CreditCardBillHistoryScreen({super.key});

  @override
  State<CreditCardBillHistoryScreen> createState() =>
      _CreditCardBillHistoryScreenState();
}

class _CreditCardBillHistoryScreenState
    extends State<CreditCardBillHistoryScreen> {
  final CreditCardBillService _billService = CreditCardBillService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  int? _selectedCardMethodId;
  int? _selectedMonthIndex;
  List<PaymentMethod> _cardMethods = [];
  List<Map<String, dynamic>> _yearBills = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUser();
      if (!mounted || user?.userId == null) return;
      final profileId = context.read<ProfileProvider>().activeProfileId;

      final methods = await _paymentMethodService.getAllPaymentMethods(
        user!.userId!,
        profileId: profileId,
      );
      final cards = methods
          .where((m) => m.type.toLowerCase() == 'card')
          .toList(growable: false);
      final yearBills = await _billService.getBillsForYear(
        user.userId!,
        _selectedYear,
        profileId: profileId,
        cardPaymentMethodId: _selectedCardMethodId,
      );

      if (!mounted) return;
      setState(() {
        _cardMethods = cards;
        _yearBills = yearBills;
      });
    } catch (e) {
      debugPrint('Error loading card bill history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectYear(int year) async {
    if (_selectedYear == year) return;
    setState(() {
      _selectedYear = year;
      _selectedMonthIndex = null;
    });
    await _loadData();
  }

  Future<void> _selectCardMethod(int? methodId) async {
    if (_selectedCardMethodId == methodId) return;
    setState(() {
      _selectedCardMethodId = methodId;
      _selectedMonthIndex = null;
    });
    await _loadData();
  }

  List<Map<String, dynamic>> _monthRows(int monthIndex) {
    final monthKey =
        '$_selectedYear-${(monthIndex + 1).toString().padLeft(2, '0')}';
    return _yearBills
        .where((row) => (row['bill_month'] as String?) == monthKey)
        .toList();
  }

  DateTime? _selectedCardIssueMonthStart() {
    if (_selectedCardMethodId == null) return null;
    final selected = _cardMethods
        .where((m) => m.paymentMethodId == _selectedCardMethodId)
        .toList();
    if (selected.isEmpty) return null;
    final issuedOn = selected.first.cardIssuedOn;
    if (issuedOn == null) return null;
    return DateTime(issuedOn.year, issuedOn.month);
  }

  String _monthStatus(int monthIndex) {
    final monthRows = _monthRows(monthIndex);
    final now = DateTime.now();
    final monthNumber = monthIndex + 1;
    final monthStart = DateTime(_selectedYear, monthNumber);
    final issueStart = _selectedCardIssueMonthStart();

    // For a specific selected card, months before card issue month are
    // not applicable and should not show details.
    if (issueStart != null && monthStart.isBefore(issueStart)) {
      return 'future';
    }

    // Future months should always stay "future" even when bill rows exist
    // (rows may be pre-generated for upcoming months).
    if (_selectedYear > now.year ||
        (_selectedYear == now.year && monthNumber > now.month)) {
      return 'future';
    }

    if (monthRows.isEmpty) {
      return 'none';
    }
    final hasOverdue = monthRows.any((row) {
      final status = (row['status'] as String?) ?? 'pending';
      if (status == 'paid') return false;
      final dueDate = DateTime.tryParse((row['due_date'] as String?) ?? '');
      return dueDate != null && dueDate.isBefore(now);
    });
    if (hasOverdue) return 'overdue';

    final hasPending = monthRows.any((row) {
      final status = (row['status'] as String?) ?? 'pending';
      return status != 'paid';
    });
    if (hasPending) return 'due';
    return 'paid';
  }

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'paid':
        return colorScheme.primary;
      case 'due':
        return const Color(0xFFF97316);
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'future':
        return colorScheme.onSurface.withValues(alpha: 0.15);
      default:
        return colorScheme.onSurface.withValues(alpha: 0.10);
    }
  }

  void _showMonthDetails(int monthIndex) {
    final status = _monthStatus(monthIndex);
    if (status == 'future') return;
    setState(() {
      _selectedMonthIndex = _selectedMonthIndex == monthIndex
          ? null
          : monthIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final years = List.generate(6, (index) => DateTime.now().year - index);
    final noBills = _yearBills.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark
                          ? const Color(0xFFe5e7eb)
                          : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    'Bill History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Yearly payment overview',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildFilterChip(
                    title: 'All Cards',
                    selected: _selectedCardMethodId == null,
                    onTap: () => _selectCardMethod(null),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  ..._cardMethods.map((card) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildFilterChip(
                        title: card.name,
                        selected: _selectedCardMethodId == card.paymentMethodId,
                        onTap: () => _selectCardMethod(card.paymentMethodId),
                        isDark: isDark,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemBuilder: (_, index) {
                  final year = years[index];
                  final isSelected = year == _selectedYear;
                  return InkWell(
                    onTap: () => _selectYear(year),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: years.length,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_selectedYear Overview',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _selectedYear == DateTime.now().year
                                      ? 'Current Year'
                                      : 'Year',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.14 : 0.05,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: 12,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 1.0,
                                      ),
                                  itemBuilder: (context, index) {
                                    final monthName = DateFormat(
                                      'MMM',
                                    ).format(DateTime(2025, index + 1));
                                    final status = _monthStatus(index);
                                    return InkWell(
                                      onTap: status == 'future'
                                          ? null
                                          : () => _showMonthDetails(index),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            context,
                                            status,
                                          ).withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          monthName,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor(
                                              context,
                                              status,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (noBills) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'No bills generated for $_selectedYear yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_selectedMonthIndex != null &&
                              _monthStatus(_selectedMonthIndex!) !=
                                  'future') ...[
                            const SizedBox(height: 14),
                            _buildInlineMonthDetailsCard(
                              context,
                              _selectedMonthIndex!,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegend(context, 'Paid', _statusColor(context, 'paid')),
                  _buildLegend(context, 'Due', _statusColor(context, 'due')),
                  _buildLegend(
                    context,
                    'Overdue',
                    _statusColor(context, 'overdue'),
                  ),
                  _buildLegend(
                    context,
                    'Future',
                    _statusColor(context, 'future'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF0c1518) : const Color(0xFF111827))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMonthDetailsCard(BuildContext context, int monthIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rows = _monthRows(monthIndex);
    final monthTitle = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(_selectedYear, monthIndex + 1));
    final currencySymbol = context.read<ProfileProvider>().currencySymbol;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              'No bills for this month',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          else
            ...rows.map((row) {
              final rowStatus = (row['status'] as String?) ?? 'pending';
              final isPaid = rowStatus == 'paid';
              final rowAmount = (row['amount'] as num?)?.toDouble();
              final amountText = rowAmount == null
                  ? '--'
                  : NumberFormat.currency(
                      locale: 'en_IN',
                      symbol: currencySymbol,
                      decimalDigits: 2,
                    ).format(rowAmount);
              final paidMethod =
                  (row['paid_payment_method_name'] as String?) ??
                  (row['payment_method_name'] as String?) ??
                  'Unknown';
              final dueDate = DateTime.tryParse(
                (row['due_date'] as String?) ?? '',
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(context, _monthStatus(monthIndex)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (row['payment_method_name'] as String?) ?? 'Card',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isPaid) ...[
                            Text(
                              'Paid: $amountText',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Method: $paidMethod',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'To Pay: $amountText',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: rowStatus == 'pending'
                                    ? const Color(0xFFF97316)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            Text(
                              dueDate != null
                                  ? 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}'
                                  : 'Due date not set',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, String title, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
