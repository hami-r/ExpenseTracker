import 'package:flutter/material.dart';

import 'reimbursement_detail_screen.dart';
import 'receivable_detail_screen.dart';
import 'add_lent_amount_screen.dart';

class MoneyOwedScreen extends StatelessWidget {
  const MoneyOwedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        _buildTotalReceivableCard(isDark),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Active Lent', isDark),
                        const SizedBox(height: 12),
                        _buildActiveLentItem(
                          context: context,
                          isDark: isDark,
                          name: 'Amit S.',
                          type: 'Personal • 0% Interest',
                          amount: '₹25,000',
                          received: '₹10,000',
                          percentage: 0.4,
                          expectedDate: 'Dec 15',
                          color: Colors.blue,
                          icon: Icons.person_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReceivableDetailScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActiveLentItem(
                          context: context,
                          isDark: isDark,
                          name: 'Sarah J.',
                          type: 'Help • 0% Interest',
                          amount: '₹5,000',
                          received: '₹1,000',
                          percentage: 0.2,
                          expectedDate: 'Nov 30',
                          color: Colors.purple,
                          icon: Icons.person_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReceivableDetailScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Pending Reimbursements', isDark),
                        const SizedBox(height: 12),
                        _buildActiveLentItem(
                          context: context,
                          isDark: isDark,
                          name: 'Office Trip',
                          type: 'Business • Travel',
                          amount: '₹95,000',
                          received: '₹45,000',
                          percentage: 0.47,
                          expectedDate: 'Next Paycheck',
                          color: Colors.orange,
                          icon: Icons.receipt_long_rounded,
                          receivedLabel: 'Approved',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReimbursementDetailScreen(),
                            ),
                          ),
                        ),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddLentAmountScreen(),
                      ),
                    );
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTotalReceivableCard(bool isDark) {
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
                '₹1,25,000',
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
