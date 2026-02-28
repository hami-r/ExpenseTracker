import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';
import 'iou_detail_screen.dart';
import 'liabilities_history_screen.dart';

import 'package:intl/intl.dart';
import '../database/services/loan_service.dart';
import '../database/services/iou_service.dart';
import '../database/services/user_service.dart';
import '../providers/profile_provider.dart';
import '../models/loan.dart';
import '../models/iou.dart';

class LiabilitiesLoansScreen extends StatefulWidget {
  const LiabilitiesLoansScreen({super.key});

  @override
  State<LiabilitiesLoansScreen> createState() => _LiabilitiesLoansScreenState();
}

class _LiabilitiesLoansScreenState extends State<LiabilitiesLoansScreen> {
  final LoanService _loanService = LoanService();
  final IOUService _iouService = IOUService();
  final UserService _userService = UserService();

  List<Loan> _loans = [];
  List<IOU> _ious = [];
  double _totalDebt = 0.0;
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _userId = user.userId;
        });

        try {
          final profileId = context.read<ProfileProvider>().activeProfileId;
          final loans = await _loanService.getActiveLoans(
            _userId!,
            profileId: profileId,
          );
          final ious = await _iouService.getActiveIOUs(
            _userId!,
            profileId: profileId,
          );

          double totalDebt = 0;
          for (var loan in loans) {
            totalDebt += (loan.principalAmount - loan.totalPaid);
          }

          for (var iou in ious) {
            totalDebt += (iou.amount - iou.totalPaid);
          }

          if (mounted) {
            setState(() {
              _loans = loans;
              _ious = ious;
              _totalDebt = totalDebt;
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error loading liabilities data: $e');
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      symbol: context.watch<ProfileProvider>().currencySymbol,
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        'Liabilities & Loans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LiabilitiesHistoryScreen(),
                            ),
                          );
                          _loadData();
                        },
                        icon: Icon(
                          Icons.history_rounded,
                          color: isDark
                              ? const Color(0xFFe5e7eb)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Debt Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark
                                  ? [
                                      const Color(0xFF1a2c26),
                                      const Color(0xFF131f17),
                                    ]
                                  : [
                                      const Color(0xFFfff7ed),
                                      const Color(0xFFffedd5),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? const Color(
                                      0xFF7c2d12,
                                    ).withValues(alpha: 0.3)
                                  : const Color(0xFFffedd5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TOTAL DEBT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isDark
                                      ? const Color(0xFFfb923c)
                                      : const Color(
                                          0xFFea580c,
                                        ).withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(_totalDebt),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFFfb923c)
                                      : const Color(0xFFea580c),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Active Loans Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Loans',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_loans.isNotEmpty)
                              Text(
                                '${_loans.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_loans.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No active loans',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          )
                        else
                          ..._loans.map((loan) {
                            final progress = loan.principalAmount > 0
                                ? loan.totalPaid / loan.principalAmount
                                : 0.0;
                            final formattedNextDue = loan.dueDate != null
                                ? DateFormat('MMM d').format(loan.dueDate!)
                                : 'No due date';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildLoanCard(
                                context: context,
                                icon: Icons.account_balance_wallet_rounded,
                                title: loan.lenderName,
                                subtitle:
                                    '${loan.loanType} • ${loan.interestRate}%',
                                amount: currencyFormat.format(
                                  loan.principalAmount,
                                ),
                                repaidAmount: currencyFormat.format(
                                  loan.totalPaid,
                                ),
                                progress: progress,
                                nextDue: formattedNextDue,
                                color:
                                    Colors.blue, // Dynamic color could be added
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoanDetailScreen(
                                        loanId: loan.loanId!,
                                      ),
                                    ),
                                  );
                                  _loadData(); // Refresh on return
                                },
                              ),
                            );
                          }),

                        const SizedBox(height: 32),

                        // Personal IOUs Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal IOUs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_ious.isNotEmpty)
                              Text(
                                '${_ious.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_ious.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No personal IOUs',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          )
                        else
                          ..._ious.map((iou) {
                            final progress = iou.amount > 0
                                ? iou.totalPaid / iou.amount
                                : 0.0;
                            final formattedNextDue = iou.dueDate != null
                                ? DateFormat('MMM d').format(iou.dueDate!)
                                : 'No due date';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildLoanCard(
                                context: context,
                                icon: Icons.handshake_rounded,
                                title: iou.creditorName,
                                subtitle: 'Personal',
                                amount: currencyFormat.format(iou.amount),
                                repaidAmount: currencyFormat.format(
                                  iou.totalPaid,
                                ),
                                progress: progress,
                                nextDue: formattedNextDue,
                                color: Colors.teal,
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IOUDetailScreen(iouId: iou.iouId!),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // FAB
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddLoanScreen(),
                    ),
                  );
                  _loadData();
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String repaidAmount,
    required double progress,
    required String nextDue,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            border: Border.all(
              color: Colors.transparent, // Placeholder for potential border
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0f172a),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94a3b8),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repaid: $repaidAmount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFf1f5f9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),

              // Footer
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.5)
                          : const Color(0xFFf8fafc),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1e293b)
                            : const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 6),
                          Text.rich(
                            TextSpan(
                              text: 'Next Due: ',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                              children: [
                                TextSpan(
                                  text: nextDue,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0f172a),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1e293b)
                            : const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF94a3b8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
