import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/services/analytics_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/user_service.dart';
import '../database/services/category_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'transaction_details_screen.dart';
import 'split_expense_detail_screen.dart';
import '../providers/profile_provider.dart';
import '../utils/icon_helper.dart';
import 'package:provider/provider.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  static const double _collapsedSheetSize = 0.41;
  static const double _maxSheetSize = 0.86;
  double _currentSheetSize = _collapsedSheetSize;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final AnalyticsService _analyticsService = AnalyticsService();
  final TransactionService _transactionService = TransactionService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();

  // Real data state
  Map<int, double> _expensesByDay = {};
  List<Transaction> _selectedDayTransactions = [];
  Map<int, Category> _categoriesMap = {};
  double _monthTotal = 0.0;
  double _dailyAvg = 0.0;
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _userId = user.userId;
        });
        await _loadMonthData();
        await _loadCategories();
        await _loadDayTransactions(_selectedDate);
      }
    }
  }

  Future<void> _loadCategories() async {
    if (_userId == null) return;
    final categories = await _categoryService.getAllCategories(_userId!);
    if (mounted) {
      setState(() {
        _categoriesMap = {for (var c in categories) c.categoryId!: c};
      });
    }
  }

  Future<void> _loadMonthData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final profileId = context.read<ProfileProvider>().activeProfileId;
      final expenses = await _analyticsService.getDailySpendingByMonth(
        _userId!,
        _currentMonth.year,
        _currentMonth.month,
        profileId: profileId,
      );

      double total = 0;
      expenses.forEach((_, amount) => total += amount);

      // Calculate days in month so far or total days in past months
      final daysInMonth = DateUtils.getDaysInMonth(
        _currentMonth.year,
        _currentMonth.month,
      );
      final isCurrentMonth =
          _currentMonth.year == DateTime.now().year &&
          _currentMonth.month == DateTime.now().month;
      final daysPassed = isCurrentMonth ? DateTime.now().day : daysInMonth;

      if (mounted) {
        setState(() {
          _expensesByDay = expenses;
          _monthTotal = total;
          _dailyAvg = daysPassed > 0 ? total / daysPassed : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading month data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDayTransactions(DateTime date) async {
    if (_userId == null) return;

    try {
      final profileId = mounted
          ? context.read<ProfileProvider>().activeProfileId
          : null;
      final transactions = await _transactionService.getTransactionsByDate(
        _userId!,
        date,
        profileId: profileId,
      );
      if (mounted) {
        setState(() {
          _selectedDayTransactions = transactions;
          _selectedDate = date;
        });
      }
    } catch (e) {
      debugPrint('Error loading day transactions: $e');
    }
  }

  Future<void> _changeMonth(int delta) async {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    final daysInNextMonth = DateUtils.getDaysInMonth(
      nextMonth.year,
      nextMonth.month,
    );
    final selectedDay = _selectedDate.day.clamp(1, daysInNextMonth);
    final nextSelectedDate = DateTime(
      nextMonth.year,
      nextMonth.month,
      selectedDay,
    );

    if (mounted) {
      setState(() {
        _currentMonth = nextMonth;
        _selectedDate = nextSelectedDate;
      });
    }

    await _loadMonthData();
    await _loadDayTransactions(nextSelectedDate);
  }

  Color _getColorFromHex(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getHeatmapColor(double? amount, BuildContext context) {
    if (amount == null || amount == 0) return Colors.transparent;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Create heatmap gradient based on theme's primary color
    if (amount < 300) {
      return primaryColor.withValues(alpha: 0.2); // heatmap-low (20%)
    }
    if (amount < 600) {
      return primaryColor.withValues(alpha: 0.5); // heatmap-med (50%)
    }
    if (amount < 900) {
      return primaryColor.withValues(alpha: 0.75); // heatmap-high (75%)
    }
    return primaryColor; // heatmap-max (100%)
  }

  bool _isDayWithDot(int day) {
    final amount = _expensesByDay[day] ?? 0;
    return amount > 700;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final collapsedSheetHeight =
                constraints.maxHeight * _collapsedSheetSize;
            final currentSheetHeight =
                constraints.maxHeight * _currentSheetSize;
            return Stack(
              children: [
                Column(
                  children: [
                    // Header
                    _buildHeader(isDark),

                    // Month Selector
                    _buildMonthSelector(isDark),

                    // Calendar Grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildWeekdayHeaders(),
                            const SizedBox(height: 8),
                            Expanded(child: _buildCalendarGrid(isDark)),
                            SizedBox(height: collapsedSheetHeight + 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if ((notification.extent - _currentSheetSize).abs() >
                        0.001) {
                      setState(() {
                        _currentSheetSize = notification.extent;
                      });
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: _collapsedSheetSize,
                    minChildSize: _collapsedSheetSize,
                    maxChildSize: _maxSheetSize,
                    builder: (context, scrollController) {
                      return _buildBottomSheet(isDark, scrollController);
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: currentSheetHeight - 32,
                  child: Center(
                    child: _buildSheetCircle(isDark, constraints.maxHeight),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
            'Expense Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFf3f4f6) : const Color(0xFF1f2937),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Color(0xFF9ca3af),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox();
        }

        final day = index - firstWeekday + 1;
        final isSelected =
            day == _selectedDate.day &&
            _currentMonth.year == _selectedDate.year &&
            _currentMonth.month == _selectedDate.month;

        return GestureDetector(
          onTap: () {
            final selectedDate = DateTime(
              _currentMonth.year,
              _currentMonth.month,
              day,
            );
            _loadDayTransactions(selectedDate);
            setState(() {
              _selectedDate = selectedDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : _getHeatmapColor(_expensesByDay[day], context),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF4b5563),
                  ),
                ),
                if (_isDayWithDot(day))
                  Positioned(
                    bottom: 8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : const Color(0xFF4b5563),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheet(bool isDark, ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFcbd5e1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Stats Row
                Container(
                  padding: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF1f2937)
                            : const Color(0xFFf3f4f6),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MONTH\'S TOTAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF9ca3af),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${context.read<ProfileProvider>().currencySymbol}${_monthTotal.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'DAILY AVG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF9ca3af),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${context.read<ProfileProvider>().currencySymbol}${_dailyAvg.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction Item
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (_selectedDayTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions on this day',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    itemCount: _selectedDayTransactions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final transaction = _selectedDayTransactions[index];
                      final category = _categoriesMap[transaction.categoryId];
                      final formattedDate = DateFormat(
                        'd MMM, h:mm a',
                      ).format(transaction.transactionDate);

                      final icon = IconHelper.getIcon(category?.iconName);
                      final color = _getColorFromHex(category?.colorHex);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final transactionMap = {
                                'id': transaction.transactionId,
                                'userId': transaction.userId,
                                'title': transaction.note ?? 'Expense',
                                'date': transaction.transactionDate,
                                'amount': transaction.amount,
                                'paymentMethodId': transaction.paymentMethodId,
                                'category': category?.name ?? 'Uncategorized',
                                'paymentMethod':
                                    'Cash', // TODO: Fetch payment method name if needed
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
                              // Refresh data
                              _loadData();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(icon, color: color, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.note ?? 'Expense',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFF9ca3af)
                                                : const Color(0xFF6b7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${context.read<ProfileProvider>().currencySymbol}${transaction.amount}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCircle(bool isDark, double viewportHeight) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (!_sheetController.isAttached) return;
        final deltaExtent = -(details.delta.dy / viewportHeight);
        final nextExtent = (_currentSheetSize + deltaExtent).clamp(
          _collapsedSheetSize,
          _maxSheetSize,
        );
        _sheetController.jumpTo(nextExtent);
        if ((nextExtent - _currentSheetSize).abs() > 0.001) {
          setState(() {
            _currentSheetSize = nextExtent;
          });
        }
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1e293b) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
