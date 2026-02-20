import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/services/iou_service.dart';
import '../models/iou.dart';
import '../models/iou_payment.dart';
import 'edit_iou_details_screen.dart';
import 'update_iou_progress_screen.dart';

class IOUDetailScreen extends StatefulWidget {
  final int iouId;

  const IOUDetailScreen({super.key, required this.iouId});

  @override
  State<IOUDetailScreen> createState() => _IOUDetailScreenState();
}

class _IOUDetailScreenState extends State<IOUDetailScreen> {
  bool _isDeleteDialogVisible = false;
  final IOUService _iouService = IOUService();
  IOU? _iou;
  List<IOUPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final iou = await _iouService.getIOUById(widget.iouId);
      final payments = await _iouService.getIOUPayments(widget.iouId);
      setState(() {
        _iou = iou;
        _payments = payments;
      });
    } catch (e) {
      debugPrint('Error loading IOU details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteIOU() async {
    try {
      await _iouService.softDeleteIOU(widget.iouId);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, true); // Go back
      }
    } catch (e) {
      debugPrint('Error deleting IOU: $e');
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
                : _iou == null
                ? const Center(child: Text('IOU not found'))
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              // Main Card
                              _buildMainCard(context, isDark),

                              const SizedBox(height: 24),

                              // Info Grid
                              _buildInfoGrid(context, isDark),

                              const SizedBox(height: 32),

                              // Payments List
                              _buildPaymentsList(isDark),

                              const SizedBox(height: 100), // Space for FAB
                            ],
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
                // Edit IOU Details Button
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1a2c26)
                          : Colors.white.withOpacity(0.95),
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
                              builder: (context) =>
                                  const EditIOUDetailsScreen(),
                            ),
                          );
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
                          ).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                              builder: (context) =>
                                  const UpdateIOUProgressScreen(),
                            ),
                          );
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
                        'Delete IOU?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to delete this IOU?\nThis action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _deleteIOU,
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
                                shadowColor: Colors.red.withOpacity(0.3),
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
                                    ).dividerColor.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
          Text(
            'IOU Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isDeleteDialogVisible = true;
              });
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14b8a6).withOpacity(0.1)
                  : const Color(0xFFf0fdf9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF14b8a6).withOpacity(0.2)
                    : const Color(0xFFccfbf1),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _iou?.creditorName ?? 'Unknown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _iou?.reason ?? 'Personal IOU',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'REMAINING AMOUNT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_iou != null ? NumberFormat.currency(locale: 'en_IN', symbol: '').format(_iou!.amount - _iou!.totalPaid).replaceAll(RegExp(r'\.00$'), '') : '0'}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Repaid: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_iou?.totalPaid ?? 0).replaceAll(RegExp(r'\.00$'), '')}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              Text(
                'Total: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(_iou?.amount ?? 0).replaceAll(RegExp(r'\.00$'), '')}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withOpacity(0.5)
                  : const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _iou != null && _iou!.amount > 0
                  ? (_iou!.totalPaid / _iou!.amount).clamp(0.0, 1.0)
                  : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, bool isDark) {
    if (_iou == null) return const SizedBox.shrink();

    final dateFormatter = DateFormat('MMM dd');
    final yearFormatter = DateFormat('yyyy');

    DateTime startDateTime = _iou!.createdAt ?? DateTime.now();
    DateTime? dueDateTime = _iou!.dueDate;

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Lending Date',
            value: dateFormatter.format(startDateTime),
            subValue: yearFormatter.format(startDateTime),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.event_available_rounded,
            label: 'Expected Repayment',
            value: dueDateTime != null
                ? dateFormatter.format(dueDateTime)
                : 'N/A',
            subValue: dueDateTime != null
                ? yearFormatter.format(dueDateTime)
                : '',
            isPrimary: true,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.percent_rounded,
            label: 'Interest Rate',
            value: '0%',
            subValue: 'Flat Rate',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    bool isPrimary = false,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isPrimary
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF94a3b8),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94a3b8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white : const Color(0xFF0f172a)),
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 10,
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : const Color(0xFF94a3b8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(bool isDark) {
    if (_payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No payments recorded yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Previous Partial Payments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._payments
            .map((payment) => _buildPaymentItem(payment, isDark))
            .toList(),
      ],
    );
  }

  Widget _buildPaymentItem(IOUPayment payment, bool isDark) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10b981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.notes?.isNotEmpty == true
                        ? payment.notes!
                        : 'Partial Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormatter.format(payment.paymentDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94a3b8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '+ ${currencyFormatter.format(payment.paymentAmount).replaceAll(RegExp(r'\.00$'), '')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10b981),
            ),
          ),
        ],
      ),
    );
  }
}
