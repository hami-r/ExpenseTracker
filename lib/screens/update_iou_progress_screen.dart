import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/iou.dart';
import '../models/iou_payment.dart';
import '../database/services/iou_service.dart';
import 'package:intl/intl.dart';

class UpdateIOUProgressScreen extends StatefulWidget {
  final int iouId;
  const UpdateIOUProgressScreen({super.key, required this.iouId});

  @override
  State<UpdateIOUProgressScreen> createState() =>
      _UpdateIOUProgressScreenState();
}

class _UpdateIOUProgressScreenState extends State<UpdateIOUProgressScreen> {
  final IOUService _iouService = IOUService();
  IOU? _iou;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  bool _isFullyPaid = false;
  double _newBalance = 0;
  double _newProgress = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateCalculations);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final iou = await _iouService.getIOUById(widget.iouId);
      if (iou != null) {
        if (mounted) {
          setState(() {
            _iou = iou;
            _updateCalculations();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading IOU: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCalculations() {
    if (_iou == null) return;

    double paymentAmount = double.tryParse(_amountController.text) ?? 0;
    if (_isFullyPaid) {
      paymentAmount = _iou!.amount - _iou!.totalPaid;
    }

    double projectedPaid = _iou!.totalPaid + paymentAmount;
    setState(() {
      _newBalance = (_iou!.amount - projectedPaid).clamp(0.0, _iou!.amount);
      _newProgress = _iou!.amount > 0
          ? (projectedPaid / _iou!.amount).clamp(0.0, 1.0)
          : 0;
    });
  }

  Future<void> _confirmUpdate() async {
    if (_iou == null) return;

    final double paymentAmount = double.tryParse(_amountController.text) ?? 0;

    if (paymentAmount <= 0 && !_isFullyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final double finalAmount = _isFullyPaid
        ? (_iou!.amount - _iou!.totalPaid)
        : paymentAmount;

    if (finalAmount <= 0) {
      Navigator.pop(context);
      return;
    }

    try {
      final payment = IOUPayment(
        iouId: _iou!.iouId!,
        paymentAmount: finalAmount,
        paymentDate: DateTime.now(),
        notes: _isFullyPaid ? 'Marked as fully paid' : 'Partial repayment',
        createdAt: DateTime.now(),
      );

      await _iouService.createIOUPayment(payment);
      await _iouService.updateIOUTotalPaid(
        _iou!.iouId!,
        _iou!.totalPaid + finalAmount,
      );

      if (_isFullyPaid || (_iou!.totalPaid + finalAmount >= _iou!.amount)) {
        final updatedIOU = IOU(
          iouId: _iou!.iouId,
          userId: _iou!.userId,
          amount: _iou!.amount,
          creditorName: _iou!.creditorName,
          dueDate: _iou!.dueDate,
          totalPaid: _iou!.totalPaid + finalAmount,
          status: 'completed',
          notes: _iou!.notes,
          createdAt: _iou!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _iouService.updateIOU(updatedIOU);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error confirming update: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving payment: $e')));
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateCalculations);
    _amountController.dispose();
    super.dispose();
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
                : _iou == null
                ? const Center(child: Text('IOU not found'))
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          child: Column(
                            children: [
                              // Repayment Info
                              _buildRepaymentInfo(isDark),

                              const SizedBox(height: 32),

                              // Amount Input Card
                              _buildAmountCard(isDark),

                              const SizedBox(height: 32),

                              // Options
                              _buildOptions(isDark),

                              const SizedBox(height: 32),

                              // Projection Card
                              _buildProjectionCard(isDark),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131f17).withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading || _iou == null
                        ? null
                        : _confirmUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
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
            'Update IOU Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 40), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildRepaymentInfo(bool isDark) {
    if (_iou == null) return const SizedBox.shrink();
    final NumberFormat currencyFormat = NumberFormat.simpleCurrency(
      name: 'INR',
      decimalDigits: 0,
    );
    final double remainingDue = _iou!.amount - _iou!.totalPaid;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF14b8a6).withOpacity(0.1)
                : const Color(0xFFccfbf1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.handshake_rounded,
            color: Color(0xFF14b8a6), // Teal color
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Repayment for ${_iou!.creditorName}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0f172a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Current Due: ${currencyFormat.format(remainingDue)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ADD REPAYMENT AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  enabled: !_isFullyPaid,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFe2e8f0),
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(
                      bottom: 16,
                      left: 24,
                    ), // Leave space for prefix
                    isDense: true,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFcbd5e1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(bool isDark) {
    return Column(
      children: [
        // Mark as Fully Paid Toggle
        Container(
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withOpacity(0.5)
                      : const Color(0xFFf1f5f9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF475569),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as Fully Paid',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Close this IOU completely',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isFullyPaid,
                onChanged: (value) {
                  setState(() {
                    _isFullyPaid = value;
                    if (value && _iou != null) {
                      _amountController.text = (_iou!.amount - _iou!.totalPaid)
                          .toStringAsFixed(0);
                    }
                    _updateCalculations();
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Next Payment Date (Disabled)
        Opacity(
          opacity: 0.5,
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.5)
                        : const Color(0xFFf1f5f9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF475569),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Payment Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Optional reminder',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _iou?.dueDate != null
                      ? DateFormat('MMM dd').format(_iou!.dueDate!)
                      : '--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionCard(bool isDark) {
    final NumberFormat currencyFormat = NumberFormat.simpleCurrency(
      name: 'INR',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.3)
            : const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFcbd5e1)
                      : const Color(0xFF475569),
                ),
              ),
              Text(
                currencyFormat.format(_newBalance),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Repayment Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
              Text(
                '${(_newProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.5)
                  : const Color(0xFFe2e8f0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _newProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF14b8a6,
                  ), // Teal color used in design for progress
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
