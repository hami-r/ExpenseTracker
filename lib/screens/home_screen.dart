import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import 'expense_calendar_screen.dart';
import 'detailed_spending_analytics_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<double> weeklySpending = [0.75, 0.45, 0.60, 0.35, 0.85, 0.55, 0.25];
  final List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF64748b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(now),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0f172a),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildIconButton(
                              Icons.calendar_today_rounded,
                              isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ExpenseCalendarScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildIconButton(
                              Icons.pie_chart_rounded,
                              isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DetailedSpendingAnalyticsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Weekly Spending Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                          Text(
                            'WEEKLY SPENDING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: isDark
                                  ? const Color(0xFF94a3b8)
                                  : const Color(0xFF64748b),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 192,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final isToday = index == 0; // Sunday is today
                                return _buildBarColumn(
                                  weekDays[index],
                                  weeklySpending[index],
                                  isToday,
                                  isDark,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard('Today', '₹ 32.0', false, isDark),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatsCard('Week', '₹ 32.0', true, isDark),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatsCard('Month', '₹ 32.0', false, isDark),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transactions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Text(
                      'TRANSACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTransactionCard(
                        'test',
                        '18 Jan, 8:33 PM',
                        'Charity',
                        'Cash',
                        '₹32.0',
                        Icons.volunteer_activism_rounded,
                        Colors.blue,
                        false,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildTransactionCard(
                        'Lunch',
                        '17 Jan',
                        'Food',
                        null,
                        '₹150.0',
                        Icons.lunch_dining_rounded,
                        Colors.orange,
                        true,
                        isDark,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            bottom: 112 + MediaQuery.of(context).padding.bottom,
            right: 24,
            child: Material(
              color: const Color(0xFF2bb961), // Primary theme color
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              shadowColor: const Color(0xFF2bb961).withOpacity(0.4),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : const Color(0xFFf1f5f9),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        Icons.dashboard_rounded,
                        'Dashboard',
                        0,
                        isDark,
                      ),
                      _buildNavItem(
                        Icons.receipt_long_rounded,
                        'Transactions',
                        1,
                        isDark,
                      ),
                      _buildNavItem(
                        Icons.account_balance_wallet_rounded,
                        'Budget',
                        2,
                        isDark,
                      ),
                      _buildNavItem(
                        Icons.person_rounded,
                        'Profile',
                        3,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBarColumn(String day, double height, bool isToday, bool isDark) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: double.infinity,
                  height: height * 192,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isToday
                        ? const Color(0xFF2bb961)
                        : isDark
                            ? const Color(0xFF064e3b).withOpacity(0.4)
                            : const Color(0xFFd1fae5),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2bb961).withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday
                    ? const Color(0xFF059669)
                    : isDark
                        ? const Color(0xFF64748b)
                        : const Color(0xFF94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected && isDark
            ? Border.all(color: const Color(0xFF334155))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1e293b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    String title,
    String date,
    String category,
    String? paymentMethod,
    String amount,
    IconData icon,
    Color iconColor,
    bool isOld,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? const Color(0xFF334155)
                  : iconColor.withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? iconColor.withOpacity(0.8)
                  : iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                    if (paymentMethod != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFcbd5e1),
                          ),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFcbd5e1),
                          ),
                        ),
                      ),
                      Text(
                        paymentMethod,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFcbd5e1),
                          ),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
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

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final primaryColor = const Color(0xFF2bb961);

    return InkWell(
      onTap: () {
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? primaryColor
                  : isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFF94a3b8),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.5,
                color: isSelected
                    ? primaryColor
                    : isDark
                        ? const Color(0xFF64748b)
                        : const Color(0xFF94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
