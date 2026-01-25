import 'package:flutter/material.dart';

class LoanPaymentHistoryScreen extends StatelessWidget {
  const LoanPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
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
                    Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.1 : 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(isDark ? 0.1 : 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, isDark),

                // Search and Filter
                _buildSearchAndFilter(isDark),

                // Payment List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      _buildMonthSection(
                        'November 2023',
                        [
                          {
                            'date': 'Nov 05, 2023',
                            'method': 'Auto-debit • SBI ****8839',
                            'amount': '₹12,500',
                            'icon': Icons.autorenew_rounded,
                          },
                        ],
                        isDark,
                      ),
                      _buildMonthSection(
                        'October 2023',
                        [
                          {
                            'date': 'Oct 05, 2023',
                            'method': 'Auto-debit • SBI ****8839',
                            'amount': '₹12,500',
                            'icon': Icons.autorenew_rounded,
                          },
                        ],
                        isDark,
                      ),
                      _buildMonthSection(
                        'September 2023',
                        [
                          {
                            'date': 'Sep 05, 2023',
                            'method': 'UPI Transfer • PhonePe',
                            'amount': '₹12,500',
                            'icon': Icons.account_balance_wallet_rounded,
                          },
                        ],
                        isDark,
                      ),
                      _buildMonthSection(
                        'August 2023',
                        [
                          {
                            'date': 'Aug 05, 2023',
                            'method': 'Auto-debit • SBI ****8839',
                            'amount': '₹12,500',
                            'icon': Icons.autorenew_rounded,
                          },
                          {
                            'date': 'Aug 01, 2023',
                            'method': 'Bank Transfer • HDFC',
                            'amount': '₹5,000',
                            'icon': Icons.account_balance_rounded,
                          },
                        ],
                        isDark,
                      ),
                      _buildMonthSection(
                        'July 2023',
                        [
                          {
                            'date': 'Jul 05, 2023',
                            'method': 'Auto-debit • SBI ****8839',
                            'amount': '₹12,500',
                            'icon': Icons.autorenew_rounded,
                          },
                        ],
                        isDark,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
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
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
          Column(
            children: [
              Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Car Loan • SBI Auto',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
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
              child: TextField(
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
                    size: 20,
                  ),
                  hintText: 'Search by amount or ID',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
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
            child: Icon(
              Icons.filter_list_rounded,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Map<String, dynamic>> payments, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            month,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color(0xFF94a3b8),
            ),
          ),
        ),
        ...payments.map((payment) => _buildPaymentCard(payment, isDark)),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFf8fafc),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  payment['icon'] as IconData,
                  color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF64748b),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['date'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment['method'] as String,
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
                payment['amount'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 10,
                      color: Color(0xFF10b981),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10b981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
