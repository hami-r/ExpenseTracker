import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  const ExpenseCalendarScreen({super.key});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  DateTime _currentMonth = DateTime.now();

  // Mock expense data - amount per day
  final Map<int, double> expensesByDay = {
    1: 150.0,
    2: 450.0,
    3: 200.0,
    4: 800.0,
    5: 1200.0,
    6: 400.0,
    7: 180.0,
    8: 160.0,
    9: 500.0,
    10: 850.0,
    11: 220.0,
    12: 190.0,
    13: 450.0,
    14: 1100.0,
    15: 175.0,
    16: 200.0,
    17: 420.0,
    18: 650.0,
    19: 900.0,
    20: 480.0,
    21: 210.0,
    22: 165.0,
    23: 430.0,
    24: 820.0,
    25: 185.0,
    26: 195.0,
    27: 510.0,
    28: 230.0,
    29: 175.0,
    30: 440.0,
    31: 200.0,
  };

  Color _getHeatmapColor(double? amount, BuildContext context) {
    if (amount == null || amount == 0) return Colors.transparent;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Create heatmap gradient based on theme's primary color
    if (amount < 300) return primaryColor.withOpacity(0.2); // heatmap-low (20%)
    if (amount < 600) return primaryColor.withOpacity(0.5); // heatmap-med (50%)
    if (amount < 900)
      return primaryColor.withOpacity(0.75); // heatmap-high (75%)
    return primaryColor; // heatmap-max (100%)
  }

  bool _isDayWithDot(int day) {
    final amount = expensesByDay[day] ?? 0;
    return amount > 700;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
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
                  ],
                ),
              ),
            ),

            // Bottom Sheet with Stats
            _buildBottomSheet(isDark),
          ],
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
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
              });
            },
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
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
              });
            },
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

    final today = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == today.year && _currentMonth.month == today.month;

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
        final amount = expensesByDay[day] ?? 0;
        final color = _getHeatmapColor(amount, context);
        final hasDot = _isDayWithDot(day);
        final isToday = isCurrentMonth && day == today.day;

        return _buildDayTile(day, color, hasDot, isToday, isDark);
      },
    );
  }

  Widget _buildDayTile(
    int day,
    Color color,
    bool hasDot,
    bool isToday,
    bool isDark,
  ) {
    final hasExpense = color != Colors.transparent;
    final isLight = color.opacity < 0.3;

    return Material(
      color: isToday
          ? (isDark ? const Color(0xFF374151) : Colors.white)
          : color,
      borderRadius: BorderRadius.circular(8),
      elevation: hasExpense ? 1 : 0,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || !isLight && hasExpense
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isToday
                      ? (isDark
                            ? const Color(0xFFf3f4f6)
                            : const Color(0xFF111827))
                      : isLight
                      ? const Color(0xFF166534)
                      : hasExpense
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFF9ca3af)
                            : const Color(0xFF6b7280)),
                ),
              ),
              if (hasDot)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Button
          Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1e293b) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
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
                              '₹38,331.0',
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
                              '₹1,236',
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.volunteer_activism_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Donation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '18 Jan, 8:33 PM',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFF9ca3af)
                                                : const Color(0xFF6b7280),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF4b5563)
                                              : const Color(0xFFd1d5db),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(
                                        'Charity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF4b5563)
                                              : const Color(0xFFd1d5db),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(
                                        'UPI',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF9ca3af)
                                              : const Color(0xFF6b7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹32.0',
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

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
