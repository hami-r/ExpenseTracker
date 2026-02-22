import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';

import '../models/reimbursement.dart';
import '../models/reimbursement_payment.dart';
import '../database/services/reimbursement_service.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class UpdateReimbursementScreen extends StatefulWidget {
  final int reimbursementId;
  const UpdateReimbursementScreen({super.key, required this.reimbursementId});

  @override
  State<UpdateReimbursementScreen> createState() =>
      _UpdateReimbursementScreenState();
}

class _UpdateReimbursementScreenState extends State<UpdateReimbursementScreen> {
  final ReimbursementService _reimbursementService = ReimbursementService();
  Reimbursement? _reimbursement;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isFullyReimbursed = false;
  final String _paymentMethod = 'Bank Transfer - HDFC';

  @override
  void initState() {
    super.initState();
    _loadData();
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    setState(() {}); // Rebuild to update summary card
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reimbursement = await _reimbursementService.getReimbursementById(
        widget.reimbursementId,
      );
      if (reimbursement != null && mounted) {
        setState(() {
          _reimbursement = reimbursement;
          final remaining =
              reimbursement.amount - reimbursement.totalReimbursed;
          _amountController.text = remaining > 0
              ? remaining.toStringAsFixed(0)
              : '';
        });
      }
    } catch (e) {
      debugPrint('Error loading reimbursement data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUpdate() async {
    if (_reimbursement == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final remaining = _reimbursement!.amount - _reimbursement!.totalReimbursed;
    final finalAmount = _isFullyReimbursed ? remaining : amount;

    try {
      final payment = ReimbursementPayment(
        reimbursementId: _reimbursement!.reimbursementId!,
        paymentAmount: finalAmount,
        paymentDate: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _reimbursementService.createReimbursementPayment(payment);

      await _reimbursementService.updateReimbursementTotalReimbursed(
        _reimbursement!.reimbursementId!,
        _reimbursement!.totalReimbursed + finalAmount,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating reimbursement payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving repayment. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    CustomDatePicker.show(
      context,
      initialDate: _selectedDate,
      onDateSelected: (DateTime picked) {
        setState(() {
          _selectedDate = picked;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(isDark ? 0.1 : 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.tertiary.withOpacity(isDark ? 0.1 : 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reimbursement == null
                ? const Center(child: Text('Reimbursement not found'))
                : Column(
                    children: [
                      _buildHeader(context, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          child: Column(
                            children: [
                              _buildAmountInput(isDark),
                              const SizedBox(height: 32),
                              _buildPaymentMethod(isDark),
                              const SizedBox(height: 16),
                              _buildDateReceived(context, isDark),
                              const SizedBox(height: 16),
                              _buildNotesInput(isDark),
                              const SizedBox(height: 32),
                              _buildSummaryCard(isDark),
                              const SizedBox(height: 24),
                              _buildFullyReimbursedToggle(isDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7))
                        .withOpacity(0),
                    (isDark
                        ? const Color(0xFF131f17)
                        : const Color(0xFFf6f8f7)),
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Settlement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
          Text(
            'Update Reimbursement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return Column(
      children: [
        Text(
          'AMOUNT RECEIVED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              context.read<ProfileProvider>().currencySymbol,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.5)
                        : const Color(0xFFe2e8f0),
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter amount received for this claim',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(bool isDark) {
    return InkWell(
      onTap: () {
        // TODO: Show payment method selector
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2c26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : const Color(0xFFf8fafc),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFe2e8f0)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      _paymentMethod,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF94a3b8),
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateReceived(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2c26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : const Color(0xFFf8fafc),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Date Received',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFe2e8f0)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1e293b)
                    : const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFcbd5e1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _notesController,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add notes (optional)',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    if (_reimbursement == null) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      symbol: context.watch<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );
    final remainingBalance =
        _reimbursement!.amount - _reimbursement!.totalReimbursed;

    double inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (_isFullyReimbursed) {
      inputAmount = remainingBalance;
    }

    final newBalance = remainingBalance - inputAmount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : const Color(0xFFecfdf5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF064e3b).withOpacity(0.3)
              : const Color(0xFFd1fae5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRANSACTION SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF34d399) : const Color(0xFF047857),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
              Text(
                currencyFormat.format(
                  remainingBalance > 0 ? remainingBalance : 0,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Received Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: Color(0xFF10b981),
                  ),
                ],
              ),
              Text(
                '- ${currencyFormat.format(inputAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10b981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? const Color(0xFF064e3b).withOpacity(0.5)
                : const Color(0xFFa7f3d0).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'New Balance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
              Text(
                currencyFormat.format(newBalance > 0 ? newBalance : 0),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullyReimbursedToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mark as Fully Reimbursed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Close this claim completely',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
          Switch(
            value: _isFullyReimbursed,
            onChanged: (value) {
              setState(() {
                _isFullyReimbursed = value;
              });
            },
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
