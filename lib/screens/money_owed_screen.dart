import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'reimbursement_detail_screen.dart';
import 'receivable_detail_screen.dart';
import 'add_lent_amount_screen.dart';
import 'money_owed_history_screen.dart';

import 'package:intl/intl.dart';
import '../database/services/receivable_service.dart';
import '../database/services/reimbursement_service.dart';
import '../database/services/user_service.dart';
import '../providers/profile_provider.dart';
import '../models/receivable.dart';
import '../models/reimbursement.dart';

class MoneyOwedScreen extends StatefulWidget {
  const MoneyOwedScreen({super.key});

  @override
  State<MoneyOwedScreen> createState() => _MoneyOwedScreenState();
}

class _MoneyOwedScreenState extends State<MoneyOwedScreen> {
  final ReceivableService _receivableService = ReceivableService();
  final ReimbursementService _reimbursementService = ReimbursementService();
  final UserService _userService = UserService();

  List<Receivable> _receivables = [];
  List<Reimbursement> _reimbursements =
      []; // Changed from _ious to _reimbursements as per screen logic
  double _totalReceivable = 0.0;
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
          // Fetch both receivables and reimbursements
          final profileId = context.read<ProfileProvider>().activeProfileId;
          final receivables = await _receivableService.getActiveReceivables(
            _userId!,
            profileId: profileId,
          );
          final reimbursements = await _reimbursementService
              .getActiveReimbursements(_userId!, profileId: profileId);

          double totalReceivable = 0;
          for (var rec in receivables) {
            totalReceivable += (rec.principalAmount - rec.totalReceived);
          }
          for (var reim in reimbursements) {
            totalReceivable += (reim.amount - reim.totalReimbursed);
          }

          if (mounted) {
            setState(() {
              _receivables = receivables;
              _reimbursements = reimbursements;
              _totalReceivable = totalReceivable;
              _isLoading = false;
            });
          }
        } catch (e) {
          debugPrint('Error loading money owed data: $e');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalReceivableCard(isDark, currencyFormat),
                        const SizedBox(height: 32),

                        // Active Lent Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader('Active Lent', isDark),
                            if (_receivables.isNotEmpty)
                              Text(
                                '${_receivables.length}',
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
                        const SizedBox(height: 12),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_receivables.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No active lent amounts',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          )
                        else
                          ..._receivables.map((receivable) {
                            final progress = receivable.principalAmount > 0
                                ? receivable.totalReceived /
                                      receivable.principalAmount
                                : 0.0;
                            final formattedExpectedDate =
                                receivable.expectedDate != null
                                ? DateFormat(
                                    'MMM d',
                                  ).format(receivable.expectedDate!)
                                : 'No date';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActiveLentItem(
                                context: context,
                                isDark: isDark,
                                name: receivable.recipientName,
                                type:
                                    '${receivable.receivableType} • ${receivable.interestRate}%',
                                amount: currencyFormat.format(
                                  receivable.principalAmount,
                                ),
                                received: currencyFormat.format(
                                  receivable.totalReceived,
                                ),
                                percentage: progress,
                                expectedDate: formattedExpectedDate,
                                color: Colors.blue, // Could be dynamic
                                icon: Icons.person_rounded,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReceivableDetailScreen(
                                            receivableId:
                                                receivable.receivableId!,
                                          ), // Passed ID
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            );
                          }),

                        const SizedBox(height: 32),
                        // Reimbursements Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader(
                              'Pending Reimbursements',
                              isDark,
                            ),
                            if (_reimbursements.isNotEmpty)
                              Text(
                                '${_reimbursements.length}',
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
                        const SizedBox(height: 12),

                        if (_isLoading)
                          const SizedBox(
                            height: 20,
                          ) // Already showing spinner above if loading
                        else if (_reimbursements.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No pending reimbursements',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._reimbursements.map((reim) {
                            final progress = reim.amount > 0
                                ? reim.totalReimbursed / reim.amount
                                : 0.0;
                            final formattedExpectedDate =
                                reim.expectedDate != null
                                ? DateFormat('MMM d').format(reim.expectedDate!)
                                : 'No date';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActiveLentItem(
                                context: context,
                                isDark: isDark,
                                name: reim.sourceName,
                                type: reim.category ?? 'Reimbursement',
                                amount: currencyFormat.format(reim.amount),
                                received: currencyFormat.format(
                                  reim.totalReimbursed,
                                ),
                                percentage: progress,
                                expectedDate: formattedExpectedDate,
                                color: Colors.orange, // Could be dynamic
                                icon: Icons.receipt_long_rounded,
                                receivedLabel: 'Reimbursed',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReimbursementDetailScreen(
                                            reimbursementId:
                                                reim.reimbursementId!,
                                          ),
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
          ),
          // FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddLentAmountScreen(),
                      ),
                    );
                    _loadData();
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
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
            'Money Owed to Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoneyOwedHistoryScreen(),
                ),
              );
              _loadData();
            },
            icon: Icon(
              Icons.history_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalReceivableCard(bool isDark, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1a2c26),
                  const Color(0xFF064e3b).withOpacity(0.3),
                ]
              : [
                  const Color(0xFFecfdf5),
                  const Color(0xFFd1fae5).withOpacity(0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF064e3b).withOpacity(0.5)
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Text(
                'TOTAL RECEIVABLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isDark
                      ? const Color(0xFF34d399)
                      : const Color(0xFF059669).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(_totalReceivable),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFF34d399)
                      : const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
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
      ],
    );
  }

  Widget _buildActiveLentItem({
    required BuildContext context,
    required bool isDark,
    required String name,
    required String type,
    required String amount,
    required String received,
    required double percentage,
    required String expectedDate,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    String receivedLabel = 'Received',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
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
                                type,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94a3b8),
                                ),
                              ),
                            ],
                          ),
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
                            const SizedBox(height: 2),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$receivedLabel: $received',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748b),
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toInt()}%',
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
                        value: percentage,
                        backgroundColor: isDark
                            ? const Color(0xFF334155).withOpacity(0.5)
                            : const Color(0xFFf1f5f9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155).withOpacity(0.5)
                          : const Color(0xFFf8fafc),
                    ),
                  ),
                ),
                child: Row(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Color(0xFF94a3b8),
                          ),
                          const SizedBox(width: 4),
                          Text.rich(
                            TextSpan(
                              text: 'Expected By: ',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748b),
                              ),
                              children: [
                                TextSpan(
                                  text: expectedDate,
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
