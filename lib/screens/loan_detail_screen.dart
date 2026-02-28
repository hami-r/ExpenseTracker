import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../database/services/loan_service.dart';
import '../models/loan.dart';
import '../models/loan_payment.dart';
import 'update_loan_screen.dart';
import 'loan_payment_history_screen.dart';
import 'edit_loan_details_screen.dart';
import '../widgets/delete_confirmation_dialog.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  bool _isDeleteDialogVisible = false;
  final LoanService _loanService = LoanService();
  Loan? _loan;
  List<LoanPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loan = await _loanService.getLoanById(widget.loanId);
      final payments = await _loanService.getLoanPayments(widget.loanId);
      setState(() {
        _loan = loan;
        _payments = payments;
      });
    } catch (e) {
      debugPrint('Error loading loan details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLoan() async {
    try {
      await _loanService.softDeleteLoan(widget.loanId);
      if (mounted) {
        setState(() => _isDeleteDialogVisible = false);
        Navigator.pop(context, true); // Go back and indicate deletion
      }
    } catch (e) {
      debugPrint('Error deleting loan: $e');
    }
  }

  Future<void> _confirmDeleteLoan() async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete Loan?',
      message:
          'Are you sure you want to delete this loan?\nThis action cannot be undone.',
    );
    if (!confirmed) return;
    await _deleteLoan();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loan == null
                ? const Center(child: Text('Loan not found'))
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                // Remaining Principal Card
                                _buildPrincipalCard(context, isDark),

                                const SizedBox(height: 24),

                                // Stats Grid
                                _buildStatsGrid(isDark),

                                const SizedBox(height: 32),

                                // Recent EMI Payments
                                _buildEMIPayments(context, isDark),

                                const SizedBox(height: 100), // Space for FAB
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                // Edit Loan Details Button
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1a2c26)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFe2e8f0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditLoanDetailsScreen(loanId: widget.loanId),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: isDark
                                  ? const Color(0xFFcbd5e1)
                                  : const Color(0xFF475569),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Loan Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFcbd5e1)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Update Progress Button
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UpdateLoanScreen(loanId: widget.loanId),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Update Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Delete Dialog Overlay
          if (_isDeleteDialogVisible) ...[
            Container(color: Colors.black.withValues(alpha: 0.5)),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Delete Loan?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to delete this loan?\nThis action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _deleteLoan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: Colors.red.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => setState(
                                () => _isDeleteDialogVisible = false,
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),

          // Loan name and lender
          Column(
            children: [
              Text(
                _loan?.loanType ?? 'Loan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _loan?.lenderName ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
            ],
          ),

          // More button / Delete button
          IconButton(
            onPressed: _confirmDeleteLoan,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipalCard(BuildContext context, bool isDark) {
    final principal = _loan?.principalAmount ?? 0.0;
    final totalPaid = _loan?.totalPaid ?? 0.0;
    final estimatedTotalPayable = (_loan?.estimatedTotalPayable ?? 0) > 0
        ? _loan!.estimatedTotalPayable
        : principal;
    final repaymentProgress = estimatedTotalPayable > 0
        ? (totalPaid / estimatedTotalPayable)
        : 0.0;
    final remainingToPayback = (estimatedTotalPayable - totalPaid).clamp(
      0.0,
      double.infinity,
    );
    final amountFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: context.read<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );
    final compactAmountFormatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: context.read<ProfileProvider>().currencySymbol,
      decimalDigits: 1,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REMAINING PAYBACK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amountFormatter.format(remainingToPayback),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Includes interest',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf97316).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFf97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _loan?.status == 'active' ? 'Active' : 'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf97316),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Paid ${amountFormatter.format(totalPaid)} of ${amountFormatter.format(estimatedTotalPayable)} '
                  '(${(repaymentProgress * 100).clamp(0.0, 100.0).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: repaymentProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: CircularProgressPainter(
                      progress: repaymentProgress,
                      color: Theme.of(context).colorScheme.primary,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFe2e8f0),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      compactAmountFormatter.format(remainingToPayback),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    Text(
                      'left',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    if (_loan == null) return const SizedBox.shrink();

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: context.read<ProfileProvider>().currencySymbol,
    );

    final stats = [
      {
        'icon': Icons.wallet_rounded,
        'color': const Color(0xFFf97316),
        'label': 'Remaining Payback',
        'value': currencyFormatter
            .format(
              ((_loan!.estimatedTotalPayable > 0
                          ? _loan!.estimatedTotalPayable
                          : _loan!.principalAmount) -
                      _loan!.totalPaid)
                  .clamp(0.0, double.infinity),
            )
            .replaceAll(RegExp(r'\.00$'), ''),
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF6366f1),
        'label': 'Total Loan',
        'value': currencyFormatter
            .format(_loan!.principalAmount)
            .replaceAll(RegExp(r'\.00$'), ''),
      },
      {
        'icon': Icons.percent_rounded,
        'color': const Color(0xFF9333ea),
        'label': 'Interest Rate',
        'value': '${_loan!.interestRate}%',
      },
      {
        'icon': Icons.stacked_line_chart_rounded,
        'color': const Color(0xFF14b8a6),
        'label': 'Interest Type',
        'value': _loan!.interestType == 'flat' ? 'Flat' : 'Reducing',
      },
      {
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF0ea5e9),
        'label': 'Tenure',
        'value': _loan!.tenureValue != null
            ? '${_loan!.tenureValue} ${_loan!.tenureUnit == 'years'
                  ? 'Yrs'
                  : _loan!.tenureUnit == 'months'
                  ? 'Mos'
                  : _loan!.tenureUnit}'
            : 'N/A',
      },
      {
        'icon': Icons.payments_rounded,
        'color': const Color(0xFFf43f5e),
        'label': 'Total Paid',
        'value': currencyFormatter
            .format(_loan!.totalPaid)
            .replaceAll(RegExp(r'\.00$'), ''),
      },
      {
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF16a34a),
        'label': 'Monthly EMI',
        'value': currencyFormatter
            .format(_loan!.estimatedEmi)
            .replaceAll(RegExp(r'\.00$'), ''),
      },
      {
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFea580c),
        'label': 'Total Interest',
        'value': currencyFormatter
            .format(_loan!.estimatedTotalInterest)
            .replaceAll(RegExp(r'\.00$'), ''),
      },
      {
        'icon': Icons.summarize_rounded,
        'color': const Color(0xFF0891b2),
        'label': 'Total You Repay',
        'value': currencyFormatter
            .format(
              _loan!.estimatedTotalPayable > 0
                  ? _loan!.estimatedTotalPayable
                  : _loan!.principalAmount,
            )
            .replaceAll(RegExp(r'\.00$'), ''),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  size: 16,
                  color: stat['color'] as Color,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat['label'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEMIPayments(BuildContext context, bool isDark) {
    if (_payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No payments recorded yet.'),
      );
    }

    final recentPayments = _payments.take(3).toList(); // Show top 3

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Payments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              if (_payments.length > 3)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoanPaymentHistoryScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...recentPayments.map((payment) => _buildPaymentItem(payment, isDark)),
      ],
    );
  }

  Widget _buildPaymentItem(LoanPayment payment, bool isDark) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: context.read<ProfileProvider>().currencySymbol,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFF10b981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormatter.format(payment.paymentDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.notes?.isNotEmpty == true
                      ? payment.notes!
                      : 'Payment',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter
                    .format(payment.paymentAmount)
                    .replaceAll(RegExp(r'\.00$'), ''),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF10b981,
                  ).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress circle
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
