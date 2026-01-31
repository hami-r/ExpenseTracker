import 'package:flutter/material.dart';
import 'edit_split_expense_screen.dart';

class SplitExpenseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const SplitExpenseDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Map tailwind colors to Flutter colors approx
    final surfaceColor = isDark
        ? const Color(0xFF1a2c26)
        : const Color(0xFFffffff);
    final backgroundColor = isDark
        ? const Color(0xFF131f17)
        : const Color(0xFFf6f8f7);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Hardcoded breakdown items for demo as per HTML
    final breakdownItems = [
      {
        'title': 'Groceries',
        'category': 'Food',
        'amount': '3,500',
        'icon': Icons.lunch_dining,
        'color': Colors.orange,
      },
      {
        'title': 'T-shirt',
        'category': 'Shopping',
        'amount': '1,500',
        'icon': Icons.checkroom,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 1. Header
                _buildHeader(context, isDark),

                // 2. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Total Amount Card
                        _buildTotalAmountCard(
                          context,
                          isDark,
                          surfaceColor,
                          primaryColor,
                        ),

                        const SizedBox(height: 32),

                        // Itemized Breakdown Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Itemized Breakdown',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0f172a),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Breakdown Items
                        ...breakdownItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBreakdownItem(
                              context,
                              isDark,
                              surfaceColor,
                              item,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Meta Info (Date, Note)
                        _buildMetaInfo(context, isDark),

                        // Bottom padding for clear view above footer
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Footer Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundColor.withOpacity(0), backgroundColor],
                  stops: const [0.0, 0.3],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditSplitExpenseScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceColor,
                        foregroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF334155),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFe2e8f0),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Details'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: Colors.red.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
            'Transaction Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTotalAmountCard(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFf1f5f9),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFFcbd5e1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '5,000',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFe2e8f0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 20,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'UPI (GPay Personal)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Map<String, dynamic> item,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: item['color'], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (item['category'] as String).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94a3b8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${item['amount']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1a2c26) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94a3b8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Today, Oct 24',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1a2c26) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                size: 20,
                color: Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94a3b8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Weekly shopping run with friends. Split 50/50 for the shared items.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFcbd5e1)
                          : const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
