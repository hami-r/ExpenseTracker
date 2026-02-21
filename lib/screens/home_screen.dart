import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_expense_screen.dart';
import 'expense_calendar_screen.dart';
import 'detailed_spending_analytics_screen.dart';
import 'profile_screen.dart';
import 'transaction_details_screen.dart';
import 'split_expense_detail_screen.dart';
import 'all_transactions_screen.dart';
import 'budget_screen.dart';
import '../database/services/analytics_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/user_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/payment_method.dart';
import '../utils/icon_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Services
  final AnalyticsService _analyticsService = AnalyticsService();
  final TransactionService _transactionService = TransactionService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();

  // Data

  Map<String, double> _weeklySpending = {};
  List<model.Transaction> _recentTransactions = [];
  Map<int, Category> _categoriesMap = {};
  Map<int, PaymentMethod> _paymentMethodsMap = {};
  double _todaySpending = 0.0;
  double _monthSpending = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        // Load analytics and transactions in parallel
        final results = await Future.wait([
          _analyticsService.getWeeklySpending(user.userId!),
          _analyticsService.getTotalBalance(user.userId!),
          _transactionService.getRecentTransactions(user.userId!, 10),
          _categoryService.getAllCategories(user.userId!),
          _paymentMethodService.getAllPaymentMethods(user.userId!),
          _analyticsService.getTotalSpending(user.userId!, now, now), // Today
          _analyticsService.getTotalSpending(
            user.userId!,
            startOfMonth,
            endOfMonth,
          ), // Month
        ]);

        if (mounted) {
          // Create maps for quick lookup
          final categories = results[3] as List<Category>;
          final paymentMethods = results[4] as List<PaymentMethod>;

          final categoriesMap = <int, Category>{};
          for (var cat in categories) {
            if (cat.categoryId != null) categoriesMap[cat.categoryId!] = cat;
          }

          final paymentMethodsMap = <int, PaymentMethod>{};
          for (var pm in paymentMethods) {
            if (pm.paymentMethodId != null)
              paymentMethodsMap[pm.paymentMethodId!] = pm;
          }

          setState(() {
            _weeklySpending = results[0] as Map<String, double>;
            _recentTransactions = results[2] as List<model.Transaction>;
            _categoriesMap = categoriesMap;
            _paymentMethodsMap = paymentMethodsMap;
            _todaySpending = results[5] as double;
            _monthSpending = results[6] as double;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading home screen data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getColorFromHex(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboard(isDark, dateFormat, now),
              const AllTransactionsScreen(),
              const BudgetScreen(),
              const ProfileScreen(),
            ],
          ),

          // Floating Action Button (Only show on Dashboard)
          if (_selectedIndex == 0)
            Positioned(
              bottom: 112 + MediaQuery.of(context).padding.bottom,
              right: 24,
              child: Material(
                color: Theme.of(
                  context,
                ).colorScheme.primary, // Primary theme color
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.4),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen(),
                      ),
                    );
                    // Reload data when coming back from add screen
                    _loadData();
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
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
                      _buildNavItem(Icons.person_rounded, 'Profile', 3, isDark),
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

  Widget _buildDashboard(bool isDark, DateFormat dateFormat, DateTime now) {
    return SafeArea(
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
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
                              builder: (context) =>
                                  const ExpenseCalendarScreen(),
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
                              builder: (context) =>
                                  const DetailedSpendingAnalyticsScreen(),
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
                          if (_weeklySpending.isEmpty) {
                            return _buildBarColumn(
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                              0.0,
                              index == 6,
                              isDark,
                            );
                          }

                          final keys = _weeklySpending.keys.toList();
                          final values = _weeklySpending.values.toList();
                          final dayName = keys[index]; // e.g. "Mon"
                          final amount = values[index];
                          // _weeklySpending returns last 7 days ending today.
                          // So the last index (6) is today.
                          final isToday = index == 6;

                          // Get first letter
                          final label = dayName.isNotEmpty
                              ? dayName.substring(0, 1)
                              : '';

                          // Normalize amount for bar height (0.0 to 1.0 relative to max)
                          // If max is 0, use 0.
                          // Wait, _buildBarColumn likely expects 0.0-1.0 or value?
                          // The hardcoded values were 0.75 etc.
                          // Let's check _buildBarColumn implementation.
                          // Assuming it takes double height factor.
                          // We need to normalize against max spending in the week.
                          double maxSpending = values.reduce(
                            (curr, next) => curr > next ? curr : next,
                          );
                          if (maxSpending == 0) maxSpending = 1.0;

                          return _buildBarColumn(
                            label,
                            amount / maxSpending, // Normalize
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
                    child: _buildStatsCard(
                      'Today',
                      '₹ ${_todaySpending.toStringAsFixed(1)}',
                      false,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Week',
                      // Calculate week total from weekly map
                      '₹ ${_weeklySpending.values.fold(0.0, (doc, val) => doc + val).toStringAsFixed(1)}',
                      true,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Month',
                      '₹ ${_monthSpending.toStringAsFixed(1)}',
                      false,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Transactions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllTransactionsScreen(),
                        ),
                      ).then((_) => _loadData()); // Reload when returning
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
            sliver: _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _recentTransactions.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent transactions',
                              style: TextStyle(
                                color: isDark ? Colors.grey : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= _recentTransactions.length) return null;

                      final transaction = _recentTransactions[index];
                      final category = _categoriesMap[transaction.categoryId];
                      final paymentMethod =
                          _paymentMethodsMap[transaction.paymentMethodId];
                      final formattedDate = DateFormat(
                        'd MMM, h:mm a',
                      ).format(transaction.transactionDate);

                      final icon = IconHelper.getIcon(category?.iconName);
                      final color = _getColorFromHex(category?.colorHex);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTransactionCard(
                          transaction.note?.isNotEmpty == true
                              ? transaction.note!
                              : (category?.name ?? 'Expense'),
                          formattedDate,
                          paymentMethod?.name,
                          transaction.amount.toString(),
                          icon,
                          color,
                          transaction.isSplit,
                          isDark,
                          onTap: () async {
                            final transactionMap = {
                              'id': transaction.transactionId,
                              'userId': transaction.userId,
                              'title': transaction.note ?? 'Expense',
                              'date': transaction.transactionDate,
                              'amount': transaction.amount,
                              'categoryId': transaction.categoryId,
                              'paymentMethodId': transaction.paymentMethodId,
                              'category': category?.name ?? 'Uncategorized',
                              'paymentMethod': paymentMethod?.name ?? 'Unknown',
                              'icon': icon,
                              'color': color,
                              'note': transaction.note ?? '',
                            };

                            if (transaction.isSplit) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SplitExpenseDetailScreen(
                                        transaction: transactionMap,
                                      ),
                                ),
                              );
                            } else {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionDetailsScreen(
                                        transaction: transactionMap,
                                      ),
                                ),
                              );
                            }
                            // Reload data in case of changes/deletion
                            _loadData();
                          },
                        ),
                      );
                    }, childCount: _recentTransactions.length),
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
                        ? Theme.of(context).colorScheme.primary
                        : isDark
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15)
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
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
                    ? Theme.of(context).colorScheme.primary
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

  Widget _buildStatsCard(
    String label,
    String value,
    bool isSelected,
    bool isDark,
  ) {
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
    String? paymentMethod,
    String amount,
    IconData icon,
    Color iconColor,
    bool isSplit,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
                      color: isDark ? iconColor.withOpacity(0.8) : iconColor,
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0f172a),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
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
                              Flexible(
                                child: Text(
                                  paymentMethod,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94a3b8)
                                        : const Color(0xFF64748b),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹$amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                ],
              ),
            ),
            if (isSplit)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_split_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Split',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () async {
        if (index == 3) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
          if (result != null && result is int) {
            setState(() {
              _selectedIndex = result;
            });
          }
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
