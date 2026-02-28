import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';
import '../models/receivable.dart';
import '../models/receivable_payment.dart';
import '../database/services/receivable_service.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class UpdateReceivableScreen extends StatefulWidget {
  final int receivableId;
  const UpdateReceivableScreen({super.key, required this.receivableId});

  @override
  State<UpdateReceivableScreen> createState() => _UpdateReceivableScreenState();
}

class _UpdateReceivableScreenState extends State<UpdateReceivableScreen> {
  final ReceivableService _receivableService = ReceivableService();
  Receivable? _receivable;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isfullySettled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _amountController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final receivable = await _receivableService.getReceivableById(
        widget.receivableId,
      );
      if (mounted) {
        setState(() {
          _receivable = receivable;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading receivable details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
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
                    ).colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.4),
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
                    Theme.of(context).colorScheme.tertiary.withValues(
                      alpha: isDark ? 0.1 : 0.3,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receivable == null
                ? const Center(child: Text('Receivable not found'))
                : Column(
                    children: [
                      _buildHeader(context, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildRecipientInfo(isDark),
                              const SizedBox(height: 32),
                              _buildAmountInput(isDark),
                              const SizedBox(height: 32),
                              _buildOptions(context, isDark),
                              const SizedBox(height: 32),
                              _buildSummaryCard(isDark),
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
                        .withValues(alpha: 0),
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
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 24, weight: 600),
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
            'Update Receivable',
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

  Widget _buildRecipientInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3b82f6).withValues(alpha: 0.2)
                  : const Color(0xFFdbeafe),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: 28,
              color: isDark ? const Color(0xFF60a5fa) : const Color(0xFF2563eb),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _receivable!.recipientName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _receivable!.expectedDate != null
                    ? 'Expected ${DateFormat('MMM dd').format(_receivable!.expectedDate!)}'
                    : 'No expected date',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return Column(
      children: [
        Text(
          'AMOUNT RECEIVED TODAY',
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
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFe2e8f0),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the amount repaid by ${_receivable!.recipientName}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Date Picker
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2c26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Repayment Date',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('dd MMM, yyyy').format(_selectedDate),
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
        ),
        const SizedBox(height: 16),
        // Settle Checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                      Icons.check_circle_rounded,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark as Fully Settled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFe2e8f0)
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Clears remaining balance completely',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _isfullySettled,
                onChanged: (value) {
                  setState(() {
                    _isfullySettled = value;
                    if (value && _receivable != null) {
                      final remainingBalance =
                          _receivable!.principalAmount -
                          _receivable!.totalReceived;
                      _amountController.text = remainingBalance.toStringAsFixed(
                        0,
                      );
                    }
                  });
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    if (_receivable == null) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      symbol: context.watch<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );
    final previousBalance =
        _receivable!.principalAmount - _receivable!.totalReceived;

    double inputAmount = 0;
    if (_amountController.text.isNotEmpty) {
      inputAmount = double.tryParse(_amountController.text) ?? 0;
    }

    double finalAmount = _isfullySettled ? previousBalance : inputAmount;
    double newBalance = previousBalance - finalAmount;
    if (newBalance < 0) newBalance = 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : const Color(0xFFecfdf5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF064e3b).withValues(alpha: 0.3)
              : const Color(0xFFd1fae5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRANSACTION SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDark
                      ? const Color(0xFF34d399)
                      : const Color(0xFF047857),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Previous Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                  Text(
                    currencyFormat.format(previousBalance),
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
                    '- ${currencyFormat.format(finalAmount)}',
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
                    ? const Color(0xFF064e3b).withValues(alpha: 0.5)
                    : const Color(0xFFa7f3d0).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'New Remaining Balance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                  Text(
                    currencyFormat.format(newBalance),
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
        ],
      ),
    );
  }

  Future<void> _confirmUpdate() async {
    if (_receivable == null) return;

    double inputAmount = 0;
    if (_amountController.text.isNotEmpty) {
      inputAmount = double.tryParse(_amountController.text) ?? 0;
    }

    final previousBalance =
        _receivable!.principalAmount - _receivable!.totalReceived;
    double finalAmount = _isfullySettled ? previousBalance : inputAmount;

    if (finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      final payment = ReceivablePayment(
        receivableId: _receivable!.receivableId!,
        paymentAmount: finalAmount,
        paymentDate: _selectedDate,
        notes: _isfullySettled
            ? 'Marked as fully Settled'
            : 'Partial repayment',
        createdAt: DateTime.now(),
      );

      await _receivableService.createReceivablePayment(payment);

      // Update the total received amount on the receivable itself
      await _receivableService.updateReceivableTotalReceived(
        _receivable!.receivableId!,
        _receivable!.totalReceived + finalAmount,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating receivable payment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving repayment. Please try again.'),
        ),
      );
    }
  }
}
