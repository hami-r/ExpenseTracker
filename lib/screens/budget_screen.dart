import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../database/services/user_service.dart';
import '../database/services/budget_service.dart';
import '../database/services/category_service.dart';
import '../models/category.dart';
import 'set_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final UserService _userService = UserService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  DateTime _selectedDate = DateTime.now();
  int? _userId;
  bool _isLoading = true;

  double _totalBudget = 0.0;
  double _totalSpent = 0.0;

  List<Budget> _budgets = [];
  Map<int?, double> _monthlySpending = {};
  List<Category> _categories = [];

  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(
    name: 'INR',
    decimalDigits: 0,
  );

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
          _isLoading = true;
        });

        try {
          // Fetch categories
          _categories = await _categoryService.getAllCategories(_userId!);

          // Use the updated date context
          final int month = _selectedDate.month;
          final int year = _selectedDate.year;

          // Fetch budgets (will auto-carry-over if needed)
          _budgets = await _budgetService.getBudgets(_userId!, month, year);

          // Fetch actual spending
          _monthlySpending = await _budgetService.getMonthlySpending(
            _userId!,
            month,
            year,
          );

          // Calculate totals dynamically from category budgets
          _totalBudget = _budgets.fold(0.0, (sum, b) => sum + b.amount);

          _totalSpent = _monthlySpending[null] ?? 0.0;
        } catch (e) {
          debugPrint('Error loading budget data: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + increment,
        1,
      );
      _isLoading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryDarkColor = Colors.teal[300] ?? primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ).copyWith(bottom: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCard(
                              isDark,
                              primaryColor,
                              primaryDarkColor,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Budget Categories',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF30353E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._buildCategoryList(isDark),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 100,
        ), // Adjusted to clear BottomNavigationBar
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (_userId == null) return;
            final needsRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SetBudgetScreen(
                  userId: _userId!,
                  month: _selectedDate.month,
                  year: _selectedDate.year,
                  existingBudgets: _budgets,
                ),
              ),
            );
            if (needsRefresh == true) {
              _loadData();
            }
          },
          backgroundColor: primaryColor,
          elevation: 6,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
          label: const Text(
            'Set New Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthYear = DateFormat('MMMM yyyy').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: isDark
          ? const Color(0xFF131f17).withValues(alpha: 0.95)
          : const Color(0xFFf6f8f7).withValues(alpha: 0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => _changeMonth(-1),
            color: isDark ? Colors.white : const Color(0xFF30353E),
          ),
          Column(
            children: [
              Text(
                monthYear,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF30353E),
                ),
              ),
              Text(
                'Budget Cycle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : const Color(0xFF717782),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: () => _changeMonth(1),
            color: isDark ? Colors.white : const Color(0xFF30353E),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    Color primaryColor,
    Color primaryDarkColor,
  ) {
    if (_budgets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No budget set for this month.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Set New Budget" to add category limits.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final remaining = _totalBudget - _totalSpent;
    final percentageLeft = (_totalBudget > 0)
        ? (remaining / _totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative Blob
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Remaining',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF717782),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(remaining),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: remaining < 0
                              ? const Color(0xFFFF3333)
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF30353E)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(percentageLeft * 100).toInt()}% Left',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? primaryColor : primaryDarkColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'of ${_currencyFormat.format(_totalBudget)} budget',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : const Color(0xFF717782),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Circular Progress
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: CircularProgressIndicator(
                            value: remaining < 0 ? 1.0 : percentageLeft,
                            strokeWidth: 10,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              remaining < 0
                                  ? const Color(0xFFFF3333)
                                  : primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: remaining < 0
                              ? const Color(0xFFFF3333)
                              : primaryColor,
                          size: 32,
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
    );
  }

  List<Widget> _buildCategoryList(bool isDark) {
    if (_budgets.where((b) => b.categoryId != null).isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No category budgets set for this month.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF717782),
              ),
            ),
          ),
        ),
      ];
    }

    final categoryBudgets = _budgets
        .where((b) => b.categoryId != null)
        .toList();
    return categoryBudgets.map((b) => _buildCategoryItem(b, isDark)).toList();
  }

  Widget _buildCategoryItem(Budget budget, bool isDark) {
    // Find category details
    final category = _categories.firstWhere(
      (c) => c.categoryId == budget.categoryId,
      orElse: () => Category(
        userId: _userId!,
        name: 'Unknown',
        iconName: 'category',
        colorHex: '#808080',
      ),
    );

    // Parse color string
    Color catColor;
    try {
      catColor = Color(
        int.parse((category.colorHex ?? '#808080').replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      catColor = Colors.grey;
    }

    // Determine status & spent
    final spent = _monthlySpending[budget.categoryId] ?? 0.0;
    final remaining = budget.amount - spent;
    final progress = (spent / budget.amount).clamp(0.0, 1.0);

    // Status colors and background matching design
    Color progressColor = catColor;
    Color bgColor = isDark ? const Color(0xFF1a2c2b) : Colors.white;
    String statusText = '${_currencyFormat.format(remaining)} remaining';
    Color statusTextColor = isDark
        ? Colors.grey[400]!
        : const Color(0xFF717782);

    if (spent >= budget.amount) {
      progressColor = const Color(0xFFFF3333); // Red
      bgColor = isDark
          ? const Color(0xFF1a2c2b)
          : const Color(0xFFFFFAFA); // Tinted bg
      statusText =
          'Overspent by ${_currencyFormat.format(spent - budget.amount)}';
      statusTextColor = progressColor;
    } else if (progress > 0.85) {
      progressColor = const Color(0xFFF5D33D); // Yellow warning
      statusTextColor = progressColor;
    } else if (spent == 0) {
      statusText = 'Untouched';
    }

    // Icon parsing
    IconData iconData = Icons.category_rounded;
    // Hardcoded minimal mapping for safety in this scope, normally use helper
    switch (category.iconName) {
      case 'restaurant':
        iconData = Icons.restaurant_rounded;
        break;
      case 'shopping_bag':
        iconData = Icons.shopping_bag_rounded;
        break;
      case 'directions_car':
        iconData = Icons.directions_car_rounded;
        break;
      case 'movie':
        iconData = Icons.movie_rounded;
        break;
      case 'home':
        iconData = Icons.home_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: progressColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF30353E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusTextColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(spent),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: spent > budget.amount
                                ? const Color(0xFFFF3333)
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF30353E)),
                          ),
                        ),
                        Text(
                          'of ${_currencyFormat.format(budget.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF717782),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
