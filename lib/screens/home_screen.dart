import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_expense_screen.dart';
import 'expense_calendar_screen.dart';
import 'detailed_spending_analytics_screen.dart';
import 'profile_screen.dart';
import 'transaction_details_screen.dart';
import 'split_expense_detail_screen.dart';
import 'all_transactions_screen.dart';
import 'budget_screen.dart';
import 'natural_language_entry_screen.dart';
import 'scan_receipt_screen.dart';
import '../database/services/analytics_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/user_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/payment_method.dart';
import '../utils/icon_helper.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _transactionsRefreshTrigger = 0;

  // Services
  final AnalyticsService _analyticsService = AnalyticsService();
  final TransactionService _transactionService = TransactionService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Map<String, double> _weeklySpending = {};
  List<model.Transaction> _recentTransactions = [];
  Map<int, Category> _categoriesMap = {};
  Map<int, PaymentMethod> _paymentMethodsMap = {};
  double _todaySpending = 0.0;
  double _monthSpending = 0.0;
  bool _isLoading = true;
  bool _isQuickAIMenuOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload whenever active profile changes
    final profileId = context.watch<ProfileProvider>().activeProfileId;
    if (_lastProfileId != null && _lastProfileId != profileId) {
      _loadData();
    }
    _lastProfileId = profileId;
  }

  int? _lastProfileId;

  Future<void> _loadData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null && mounted) {
        final profileId = context.read<ProfileProvider>().activeProfileId;
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        // Load analytics and transactions in parallel
        final results = await Future.wait([
          _analyticsService.getWeeklySpending(
            user.userId!,
            profileId: profileId,
          ),
          _analyticsService.getTotalBalance(user.userId!, profileId: profileId),
          _transactionService.getRecentTransactions(
            user.userId!,
            10,
            profileId: profileId,
          ),
          _categoryService.getAllCategories(user.userId!),
          _paymentMethodService.getAllPaymentMethods(
            user.userId!,
            profileId: profileId,
          ),
          _analyticsService.getTotalSpending(
            user.userId!,
            now,
            now,
            profileId: profileId,
          ), // Today
          _analyticsService.getTotalSpending(
            user.userId!,
            startOfMonth,
            endOfMonth,
            profileId: profileId,
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
            if (pm.paymentMethodId != null) {
              paymentMethodsMap[pm.paymentMethodId!] = pm;
            }
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
              _buildDashboard(
                isDark,
                dateFormat,
                now,
                context.watch<ProfileProvider>().currencySymbol,
              ),
              AllTransactionsScreen(
                refreshTrigger: _transactionsRefreshTrigger,
              ),
              const BudgetScreen(),
              const ProfileScreen(),
            ],
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildNavItem(
                              Icons.dashboard_rounded,
                              'Dashboard',
                              0,
                              isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildNavItem(
                              Icons.receipt_long_rounded,
                              'Transactions',
                              1,
                              isDark,
                            ),
                          ),
                          Expanded(child: _buildCenterAddNavItem(isDark)),
                          Expanded(
                            child: _buildNavItem(
                              Icons.account_balance_wallet_rounded,
                              'Budget',
                              2,
                              isDark,
                            ),
                          ),
                          Expanded(
                            child: _buildNavItem(
                              Icons.person_rounded,
                              'Profile',
                              3,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Consumer<ProfileProvider>(
                        builder: (context, profileProvider, child) {
                          return Text(
                            'Active Region: ${profileProvider.profileName}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF64748b)
                                  : const Color(0xFF94a3b8),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick AI Menu (double-tap on + to toggle)
          Positioned(
            left: 0,
            right: 0,
            bottom: 94 + MediaQuery.of(context).padding.bottom,
            child: IgnorePointer(
              ignoring: !_isQuickAIMenuOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: _isQuickAIMenuOpen ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  offset: _isQuickAIMenuOpen
                      ? Offset.zero
                      : const Offset(0, 0.15),
                  child: Center(child: _buildQuickAIMenu(isDark)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    bool isDark,
    DateFormat dateFormat,
    DateTime now,
    String currencySymbol,
  ) {
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
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
                    ),
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
                      _formatStatsAmount(_todaySpending, currencySymbol),
                      false,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Week',
                      // Calculate week total from weekly map
                      _formatStatsAmount(
                        _weeklySpending.values.fold(
                          0.0,
                          (sum, value) => sum + value,
                        ),
                        currencySymbol,
                      ),
                      true,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatsCard(
                      'Month',
                      _formatStatsAmount(_monthSpending, currencySymbol),
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
                          currencySymbol,
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

  Widget _buildIconButton(
    IconData icon,
    bool isDark, {
    VoidCallback? onTap,
    Color? color,
  }) {
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
            color:
                color ??
                (isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569)),
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
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1e293b),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatsAmount(double amount, String currencySymbol) {
    if (amount == 0) return '$currencySymbol 0';

    final absolute = amount.abs();
    if (absolute >= 1000) {
      final compact = NumberFormat.compact(locale: 'en_IN').format(amount);
      return '$currencySymbol $compact';
    }

    final hasFraction = amount != amount.truncateToDouble();
    final formatted = hasFraction
        ? amount.toStringAsFixed(1)
        : amount.toStringAsFixed(0);
    return '$currencySymbol $formatted';
  }

  Widget _buildTransactionCard(
    String title,
    String date,
    String? paymentMethod,
    String amount,
    IconData icon,
    Color iconColor,
    bool isSplit,
    bool isDark,
    String currencySymbol, {
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
                    '$currencySymbol$amount',
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

  Widget _buildCenterAddNavItem(bool isDark) {
    return GestureDetector(
      onTap: () async {
        if (_isQuickAIMenuOpen) {
          setState(() => _isQuickAIMenuOpen = false);
        }
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
        );
        if (saved == true) {
          _refreshHomeData();
        }
      },
      onDoubleTap: () {
        setState(() => _isQuickAIMenuOpen = !_isQuickAIMenuOpen);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAIMenu(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.55)
              : const Color(0xFFe2e8f0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickAIMenuItem(
            icon: Icons.abc_rounded,
            label: 'Text / Voice AI',
            isDark: isDark,
            onTap: () async {
              setState(() => _isQuickAIMenuOpen = false);
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const NaturalLanguageEntryScreen(),
                ),
              );
              if (saved == true) {
                _refreshHomeData();
              }
            },
          ),
          const SizedBox(width: 10),
          _buildQuickAIMenuItem(
            icon: Icons.document_scanner_rounded,
            label: 'Receipt AI',
            isDark: isDark,
            onTap: () async {
              setState(() => _isQuickAIMenuOpen = false);
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanReceiptScreen(),
                ),
              );
              if (saved == true) {
                _refreshHomeData();
              }
            },
          ),
        ],
      ),
    );
  }

  void _refreshHomeData() {
    _loadData();
    if (mounted) {
      setState(() {
        _transactionsRefreshTrigger++;
      });
    }
  }

  Widget _buildQuickAIMenuItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFe2e8f0)
                      : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _isQuickAIMenuOpen = false;
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
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
