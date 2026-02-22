import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/services/receivable_service.dart';
import '../database/services/reimbursement_service.dart';
import '../database/services/user_service.dart';
import '../models/receivable.dart';
import '../models/reimbursement.dart';
import '../providers/profile_provider.dart';
import 'receivable_detail_screen.dart';
import 'reimbursement_detail_screen.dart';

class MoneyOwedHistoryScreen extends StatefulWidget {
  const MoneyOwedHistoryScreen({super.key});

  @override
  State<MoneyOwedHistoryScreen> createState() => _MoneyOwedHistoryScreenState();
}

class _MoneyOwedHistoryScreenState extends State<MoneyOwedHistoryScreen> {
  final ReceivableService _receivableService = ReceivableService();
  final ReimbursementService _reimbursementService = ReimbursementService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  List<Receivable> _completedReceivables = [];
  List<Reimbursement> _completedReimbursements = [];

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
        _receivableService.getCompletedReceivables(
          user!.userId!,
          profileId: profileId,
        ),
        _reimbursementService.getCompletedReimbursements(
          user.userId!,
          profileId: profileId,
        ),
      ]);

      if (mounted) {
        setState(() {
          _completedReceivables = results[0] as List<Receivable>;
          _completedReimbursements = results[1] as List<Reimbursement>;
        });
      }
    } catch (e) {
      debugPrint('Error loading money owed history: $e');
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
              padding: const EdgeInsets.all(24).copyWith(bottom: 8),
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
                    'Money Owed History',
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
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Completed Lent',
                            _completedReceivables.length,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          if (_completedReceivables.isEmpty)
                            _buildEmptyState(
                              'No completed lent records',
                              isDark,
                            )
                          else
                            ..._completedReceivables.map(
                              (item) => _buildHistoryItem(
                                title: item.recipientName,
                                subtitle: '${item.receivableType} • Completed',
                                amount: currencyFormat.format(
                                  item.principalAmount,
                                ),
                                icon: Icons.person_rounded,
                                color: Colors.blue,
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReceivableDetailScreen(
                                            receivableId: item.receivableId!,
                                          ),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            ),
                          const SizedBox(height: 28),
                          _buildSectionHeader(
                            'Completed Reimbursements',
                            _completedReimbursements.length,
                            isDark,
                          ),
                          const SizedBox(height: 12),
                          if (_completedReimbursements.isEmpty)
                            _buildEmptyState(
                              'No completed reimbursements',
                              isDark,
                            )
                          else
                            ..._completedReimbursements.map(
                              (item) => _buildHistoryItem(
                                title: item.sourceName,
                                subtitle:
                                    '${item.category ?? 'Reimbursement'} • Completed',
                                amount: currencyFormat.format(item.amount),
                                icon: Icons.receipt_long_rounded,
                                color: Colors.orange,
                                isDark: isDark,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReimbursementDetailScreen(
                                            reimbursementId:
                                                item.reimbursementId!,
                                          ),
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

  Widget _buildHistoryItem({
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
                    ? const Color(0xFF334155).withOpacity(0.4)
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
                      color: color.withOpacity(0.12),
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

  Widget _buildEmptyState(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
