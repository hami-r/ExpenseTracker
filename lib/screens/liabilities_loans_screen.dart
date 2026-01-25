import 'dart:ui';
import 'package:flutter/material.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';
import 'iou_detail_screen.dart';

class LiabilitiesLoansScreen extends StatelessWidget {
  const LiabilitiesLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      Text(
                        'Liabilities & Loans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(width: 40),
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
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                                  ? const Color(0xFF7c2d12).withOpacity(0.3)
                                  : const Color(0xFFffedd5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                      : const Color(0xFFea580c).withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹14,25,000',
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
                        const Text(
                          'Active Loans',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLoanCard(
                          context: context,
                          icon: Icons.directions_car_rounded,
                          title: 'Car Loan',
                          subtitle: 'SBI Auto • 8.65%',
                          amount: '₹5.5L',
                          repaidAmount: '₹3.2L',
                          progress: 0.58,
                          nextDue: 'Nov 05',
                          color: Colors.blue,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildLoanCard(
                          context: context,
                          icon: Icons.school_rounded,
                          title: 'Education Loan',
                          subtitle: 'HDFC • 9.2%',
                          amount: '₹8.0L',
                          repaidAmount: '₹1.2L',
                          progress: 0.15,
                          nextDue: 'Nov 12',
                          color: Colors.indigo,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 32),

                        // Personal IOUs Section
                        const Text(
                          'Personal IOUs',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLoanCard(
                          context: context,
                          icon: Icons.handshake_rounded,
                          title: 'Rahul K.',
                          subtitle: 'Personal • 0% Interest',
                          amount: '₹50,000',
                          repaidAmount: '₹25,000',
                          progress: 0.50,
                          nextDue: 'Dec 01',
                          color: Colors.teal,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IOUDetailScreen(),
                              ),
                            );
                          },
                        ),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddLoanScreen(),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoanDetailScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
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
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
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
              backgroundColor: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFf1f5f9),
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
                  color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFf8fafc),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
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
                                color: isDark ? Colors.white : const Color(0xFF0f172a),
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
                    color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
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
