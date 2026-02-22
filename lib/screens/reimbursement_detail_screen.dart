import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_reimbursement_screen.dart';
import 'update_reimbursement_screen.dart';
import '../models/reimbursement.dart';
import '../models/reimbursement_payment.dart';
import '../database/services/reimbursement_service.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class ReimbursementDetailScreen extends StatefulWidget {
  final int reimbursementId;
  const ReimbursementDetailScreen({super.key, required this.reimbursementId});

  @override
  State<ReimbursementDetailScreen> createState() =>
      _ReimbursementDetailScreenState();
}

class _ReimbursementDetailScreenState extends State<ReimbursementDetailScreen> {
  final ReimbursementService _reimbursementService = ReimbursementService();
  Reimbursement? _reimbursement;
  List<ReimbursementPayment> _payments = [];
  bool _isLoading = true;
  bool _isDeleteDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reimbursement = await _reimbursementService.getReimbursementById(
        widget.reimbursementId,
      );
      final payments = await _reimbursementService.getReimbursementPayments(
        widget.reimbursementId,
      );

      if (mounted) {
        setState(() {
          _reimbursement = reimbursement;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reimbursement data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReimbursement() async {
    try {
      await _reimbursementService.softDeleteReimbursement(
        widget.reimbursementId,
      );
      if (mounted) {
        setState(() => _isDeleteDialogVisible = false);
        Navigator.pop(context, true); // Indicate deletion
      }
    } catch (e) {
      debugPrint('Error deleting reimbursement: $e');
    }
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
                : _reimbursement == null
                ? const Center(child: Text('Reimbursement not found'))
                : Column(
                    children: [
                      _buildHeader(context, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainCard(isDark),
                              const SizedBox(height: 12),
                              _buildGridInfo(isDark),
                              const SizedBox(height: 24),
                              _buildReceivedPayments(isDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1a2c26) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFe2e8f0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditReimbursementScreen(
                                reimbursementId: widget.reimbursementId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFFcbd5e1)
                                  : const Color(0xFF334155),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Details',
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
                          ).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateReimbursementScreen(
                                reimbursementId: widget.reimbursementId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Update Progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

          if (_isDeleteDialogVisible) _buildDeleteDialogOverlay(context),
        ],
      ),
    );
  }

  // Delete Dialog Overlay (added to the stack before it ends)
  Widget _buildDeleteDialogOverlay(BuildContext context) {
    if (!_isDeleteDialogVisible) return const SizedBox.shrink();
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.5)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
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
                    'Delete Reimbursement?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete this expected reimbursement?\nThis action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isDeleteDialogVisible = false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _deleteReimbursement,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
            'Reimbursement Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isDeleteDialogVisible = true);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(bool isDark) {
    if (_reimbursement == null) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      symbol: context.watch<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );
    final remainingBalance =
        _reimbursement!.amount - _reimbursement!.totalReimbursed;
    final progress = _reimbursement!.amount > 0
        ? (_reimbursement!.totalReimbursed / _reimbursement!.amount)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFf97316).withOpacity(0.2)
                      : const Color(0xFFfff7ed),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.work_rounded,
                  size: 28,
                  color: isDark
                      ? const Color(0xFFfb923c)
                      : const Color(0xFFea580c),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reimbursement!.sourceName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reimbursement ID #${_reimbursement!.reimbursementId}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'REMAINING BALANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(remainingBalance > 0 ? remainingBalance : 0),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1e293b).withOpacity(0.5)
                  : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFf1f5f9),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APPROVED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isDark
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF94a3b8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(
                            _reimbursement!.totalReimbursed,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10b981),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL CLAIM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isDark
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF94a3b8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(_reimbursement!.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0f172a),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFe2e8f0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress > 1.0 ? 1.0 : progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10b981).withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF34d399)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridInfo(bool isDark) {
    if (_reimbursement == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoBox(
                icon: Icons.calendar_today_rounded,
                label: 'SUBMISSION',
                value: _reimbursement!.createdAt != null
                    ? DateFormat(
                        'MMM dd, yyyy',
                      ).format(_reimbursement!.createdAt!)
                    : 'Unknown',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoBox(
                icon: Icons.schedule_rounded,
                label: 'EXPECTED BY',
                value: _reimbursement!.expectedDate != null
                    ? DateFormat(
                        'MMM dd, yyyy',
                      ).format(_reimbursement!.expectedDate!)
                    : 'Not set',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.5)
                  : const Color(0xFFf1f5f9),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF94a3b8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _reimbursement!.category?.isNotEmpty == true
                        ? _reimbursement!.category!
                        : 'Uncategorized',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1e293b)
                      : const Color(0xFFf1f5f9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFF64748b),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFF94a3b8),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedPayments(bool isDark) {
    if (_payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No payments received yet.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: context.watch<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Received Payments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._payments.map((payment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentItem(
              title: payment.notes?.isNotEmpty == true
                  ? payment.notes!
                  : 'Payment Received',
              date: DateFormat('MMM dd').format(payment.paymentDate),
              amount: '+ ${currencyFormat.format(payment.paymentAmount)}',
              isDark: isDark,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentItem({
    required String title,
    required String date,
    required String amount,
    required bool isDark,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF10b981).withOpacity(0.2)
                      : const Color(0xFFecfdf5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  size: 20,
                  color: Color(0xFF10b981),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
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
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10b981),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Processed',
                style: TextStyle(
                  fontSize: 10,
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
}
