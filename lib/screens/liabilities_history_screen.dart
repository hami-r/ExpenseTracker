import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/services/iou_service.dart';
import '../database/services/loan_service.dart';
import '../database/services/user_service.dart';
import '../models/iou.dart';
import '../models/loan.dart';
import '../providers/profile_provider.dart';
import 'iou_detail_screen.dart';
import 'loan_detail_screen.dart';

class LiabilitiesHistoryScreen extends StatefulWidget {
  const LiabilitiesHistoryScreen({super.key});

  @override
  State<LiabilitiesHistoryScreen> createState() =>
      _LiabilitiesHistoryScreenState();
}

class _LiabilitiesHistoryScreenState extends State<LiabilitiesHistoryScreen> {
  final LoanService _loanService = LoanService();
  final IOUService _iouService = IOUService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  List<Loan> _completedLoans = [];
  List<IOU> _completedIOUs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUser();
      if (user?.userId == null) return;

      final profileId = mounted
          ? context.read<ProfileProvider>().activeProfileId
          : null;

      final results = await Future.wait([
        _loanService.getCompletedLoans(user!.userId!, profileId: profileId),
        _iouService.getCompletedIOUs(user.userId!, profileId: profileId),
      ]);

      if (mounted) {
        setState(() {
          _completedLoans = results[0] as List<Loan>;
          _completedIOUs = results[1] as List<IOU>;
        });
      }
    } catch (e) {
      debugPrint('Error loading liabilities history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    'Loans & IOUs History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark
                          ? const Color(0xFFe5e7eb)
                          : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Completed Loans',
                            _completedLoans.length,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          if (_completedLoans.isEmpty)
                            _buildEmptyState('No completed loans', isDark)
                          else
                            ..._completedLoans.map(
                              (loan) => _buildHistoryCard(
                                title: loan.lenderName,
                                subtitle: 'Loan • Completed',
                                amount: currencyFormat.format(
                                  loan.principalAmount,
                                ),
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.blue,
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoanDetailScreen(
                                        loanId: loan.loanId!,
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            'Completed Personal IOUs',
                            _completedIOUs.length,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          if (_completedIOUs.isEmpty)
                            _buildEmptyState(
                              'No completed personal IOUs',
                              isDark,
                            )
                          else
                            ..._completedIOUs.map(
                              (iou) => _buildHistoryCard(
                                title: iou.creditorName,
                                subtitle: 'Personal IOU • Completed',
                                amount: currencyFormat.format(iou.amount),
                                icon: Icons.handshake_rounded,
                                color: Colors.teal,
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          IOUDetailScreen(iouId: iou.iouId!),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0f172a),
          ),
        ),
        if (count > 0)
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2c26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.4)
                    : const Color(0xFFf1f5f9),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0f172a),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
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
                  const SizedBox(width: 8),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
