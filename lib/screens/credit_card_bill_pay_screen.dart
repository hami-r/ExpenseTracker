import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../database/services/credit_card_bill_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../models/payment_method.dart';
import '../providers/profile_provider.dart';
import '../widgets/custom_date_picker.dart';

class CreditCardBillPayScreen extends StatefulWidget {
  final bool embedded;

  const CreditCardBillPayScreen({super.key, this.embedded = false});

  @override
  State<CreditCardBillPayScreen> createState() =>
      _CreditCardBillPayScreenState();
}

class _CreditCardBillPayScreenState extends State<CreditCardBillPayScreen> {
  final CreditCardBillService _billService = CreditCardBillService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final UserService _userService = UserService();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _bills = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUser();
      if (!mounted || user?.userId == null) return;
      final profileId = context.read<ProfileProvider>().activeProfileId;
      final bills = await _billService.getBillsForMonth(
        user!.userId!,
        _selectedMonth,
        profileId: profileId,
      );
      final methods = await _paymentMethodService.getAllPaymentMethods(
        user.userId!,
        profileId: profileId,
      );
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _paymentMethods = methods;
      });
    } catch (e) {
      debugPrint('Error loading credit card bills: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load bills: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    await _loadBills();
  }

  Future<void> _togglePaid(Map<String, dynamic> bill) async {
    final billId = bill['credit_card_bill_id'] as int?;
    final status = (bill['status'] as String?) ?? 'pending';
    final defaultPaidMethodId =
        (bill['paid_payment_method_id'] as int?) ??
        (bill['payment_method_id'] as int?);
    if (billId == null) return;
    await _billService.markBillStatus(
      billId: billId,
      isPaid: status != 'paid',
      paidPaymentMethodId: defaultPaidMethodId,
    );
    await _loadBills();
  }

  Future<void> _editBill(Map<String, dynamic> bill) async {
    final billId = bill['credit_card_bill_id'] as int?;
    if (billId == null) return;
    final amountController = TextEditingController(
      text: bill['amount'] != null ? (bill['amount'] as num).toString() : '',
    );
    DateTime selectedDueDate =
        DateTime.tryParse((bill['due_date'] as String?) ?? '') ??
        DateTime.now();
    bool markAsPaid = ((bill['status'] as String?) ?? 'pending') == 'paid';
    int? selectedPaidMethodId =
        (bill['paid_payment_method_id'] as int?) ??
        (bill['payment_method_id'] as int?);
    final methodName = (bill['payment_method_name'] as String?) ?? 'Card';
    final accountNumber =
        (bill['payment_method_account_number'] as String?) ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.scaffoldBackgroundColor;
    final sectionBg = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
      sheetBg,
    );
    final mutedText = colorScheme.onSurface.withValues(alpha: 0.65);
    if (_paymentMethods.isNotEmpty &&
        selectedPaidMethodId != null &&
        !_paymentMethods.any(
          (m) => m.paymentMethodId == selectedPaidMethodId,
        )) {
      selectedPaidMethodId = _paymentMethods.first.paymentMethodId;
    }
    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: Icon(Icons.close_rounded, color: mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: mutedText,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixText:
                            '${context.read<ProfileProvider>().currencySymbol} ',
                        prefixStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: mutedText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: mutedText,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                CustomDatePicker.show(
                                  context,
                                  initialDate: selectedDueDate,
                                  onDateSelected: (value) {
                                    setSheetState(
                                      () => selectedDueDate = value,
                                    );
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: sectionBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(selectedDueDate),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: mutedText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'METHOD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: mutedText,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: sectionBg,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: selectedPaidMethodId,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: mutedText,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  hint: Text(
                                    '$methodName - ${_maskCardNumber(accountNumber).replaceFirst('**** ', '')}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setSheetState(
                                      () => selectedPaidMethodId = value,
                                    );
                                  },
                                  items: _paymentMethods
                                      .map((method) {
                                        final methodId = method.paymentMethodId;
                                        if (methodId == null) {
                                          return null;
                                        }
                                        return DropdownMenuItem<int>(
                                          value: methodId,
                                          child: Text(
                                            method.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      })
                                      .whereType<DropdownMenuItem<int>>()
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withValues(alpha: 0.16),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as Paid',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Transaction completed',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: markAsPaid,
                          onChanged: (value) {
                            setSheetState(() => markAsPaid = value);
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: colorScheme.outlineVariant,
                          trackOutlineColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text(
                        'Update Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (shouldSave != true) return;
    final parsedAmount = double.tryParse(amountController.text.trim());
    await _billService.updateBillDetails(
      billId: billId,
      dueDate: selectedDueDate,
      amount: parsedAmount,
      paidPaymentMethodId: selectedPaidMethodId,
    );
    await _billService.markBillStatus(
      billId: billId,
      isPaid: markAsPaid,
      paidPaymentMethodId: selectedPaidMethodId,
    );
    await _loadBills();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final body = Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bills.isEmpty
              ? Center(
                  child: Text(
                    'No credit card payment methods found',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
                    return _buildBillCard(
                      context: context,
                      bill: bill,
                      isDark: isDark,
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Credit Card Bill Pay')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: body,
        ),
      ),
    );
  }

  Widget _buildBillCard({
    required BuildContext context,
    required Map<String, dynamic> bill,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
    final status = (bill['status'] as String?) ?? 'pending';
    final isPaid = status == 'paid';
    final dueDate = DateTime.tryParse((bill['due_date'] as String?) ?? '');
    final paidAt = DateTime.tryParse((bill['paid_at'] as String?) ?? '');
    final paidMethodName = (bill['paid_payment_method_name'] as String?);
    final cardName = (bill['payment_method_name'] as String?) ?? 'Card';
    final accountNumber =
        (bill['payment_method_account_number'] as String?) ?? '';
    final currencySymbol = context.read<ProfileProvider>().currencySymbol;
    final amountInteger = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 0,
    ).format(amount);
    final amountDecimal = (amount - amount.floorToDouble()).abs();
    final decimalText =
        '.${(amountDecimal * 100).round().toString().padLeft(2, '0')}';
    final statusColor = isPaid ? colorScheme.primary : const Color(0xFFef4444);
    final statusBg = isPaid
        ? colorScheme.primary.withValues(alpha: 0.14)
        : const Color(0xFFfee2e2);
    final cardBg = theme.cardColor;
    final iconBg = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
      cardBg,
    );
    final mutedText = colorScheme.onSurface.withValues(alpha: 0.65);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.diamond_outlined
                          : Icons.account_balance_wallet_outlined,
                      size: 28,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _maskCardNumber(accountNumber),
                          style: TextStyle(fontSize: 14, color: mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPaid
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.circle,
                              size: isPaid ? 16 : 8,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPaid ? 'PAID' : 'PENDING',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _editBill(bill),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isPaid ? 'Total Paid' : 'Total Due',
                style: TextStyle(fontSize: 14, color: mutedText),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountInteger,
                    style: TextStyle(
                      fontSize: 46,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      decimalText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_outline_rounded
                        : Icons.event_rounded,
                    size: 16,
                    color: isPaid
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFFef4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPaid
                        ? 'Paid on ${DateFormat('MMM dd, yyyy').format(paidAt ?? DateTime.now())}'
                        : 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate ?? DateTime.now())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPaid
                          ? colorScheme.primary
                          : const Color(0xFFef4444),
                    ),
                  ),
                ],
              ),
              if (isPaid && paidMethodName != null && paidMethodName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Via: $paidMethodName',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mutedText,
                    ),
                  ),
                ),
              if (!isPaid) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _togglePaid(bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mark as Paid',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.check_rounded, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color:
                    (isPaid ? const Color(0xFF22c55e) : const Color(0xFFef4444))
                        .withValues(alpha: isDark ? 0.10 : 0.08),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _maskCardNumber(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return '****';
    return '**** ${digits.substring(digits.length - 4)}';
  }
}
