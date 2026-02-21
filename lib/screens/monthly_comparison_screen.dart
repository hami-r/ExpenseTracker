import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/services/analytics_service.dart';
import '../database/services/user_service.dart';
import '../models/category.dart';
import '../utils/icon_helper.dart';
import '../utils/color_helper.dart';

class MonthlyComparisonScreen extends StatefulWidget {
  const MonthlyComparisonScreen({super.key});

  @override
  State<MonthlyComparisonScreen> createState() =>
      _MonthlyComparisonScreenState();
}

class _MonthlyComparisonScreenState extends State<MonthlyComparisonScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final UserService _userService = UserService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  int? _userId;

  // Monthly totals for last 6 months
  List<_MonthData> _monthlyData = [];

  // Current vs previous month
  double _currentMonthTotal = 0;
  double _previousMonthTotal = 0;

  // Category deltas (current vs previous)
  List<_CategoryDelta> _topCategoryChanges = [];

  // Bar chart interaction
  int? _tappedMonthIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    if (user == null || !mounted) return;
    _userId = user.userId;

    final now = DateTime.now();

    // Fetch last 6 months totals
    final List<_MonthData> months = [];
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final start = DateTime(targetDate.year, targetDate.month, 1);
      final end = DateTime(targetDate.year, targetDate.month + 1, 0);
      final total = await _analyticsService.getTotalSpending(
        _userId!,
        start,
        end,
      );
      months.add(
        _MonthData(
          label: DateFormat('MMM').format(targetDate),
          amount: total,
          isCurrent: i == 0,
        ),
      );
    }

    setState(() {
      _monthlyData = months;
      _currentMonthTotal = months.isNotEmpty ? months.last.amount : 0;
      _previousMonthTotal = months.length >= 2
          ? months[months.length - 2].amount
          : 0;
    });

    // Category deltas
    final currentStart = DateTime(now.year, now.month, 1);
    final currentEnd = DateTime(now.year, now.month + 1, 0);
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevStart = DateTime(prevMonthDate.year, prevMonthDate.month, 1);
    final prevEnd = DateTime(prevMonthDate.year, prevMonthDate.month + 1, 0);

    final currentCats = await _analyticsService.getSpendingByCategory(
      _userId!,
      currentStart,
      currentEnd,
    );
    final prevCats = await _analyticsService.getSpendingByCategory(
      _userId!,
      prevStart,
      prevEnd,
    );

    final List<_CategoryDelta> deltas = [];
    for (final entry in currentCats.entries) {
      final cat = entry.key;
      final currAmt = entry.value;
      final prevAmt = prevCats.entries
          .firstWhere(
            (e) => e.key.categoryId == cat.categoryId,
            orElse: () => MapEntry(cat, 0),
          )
          .value;
      if (currAmt != prevAmt) {
        deltas.add(
          _CategoryDelta(
            category: cat,
            currentAmount: currAmt,
            previousAmount: prevAmt,
          ),
        );
      }
    }
    // Sort by biggest absolute change
    deltas.sort((a, b) => b.absoluteChange.compareTo(a.absoluteChange));

    if (mounted) {
      setState(() {
        _topCategoryChanges = deltas.take(5).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Monthly Comparison',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNetChangeCard(isDark, primaryColor),
                          const SizedBox(height: 20),
                          _buildBarChart(isDark, primaryColor),
                          const SizedBox(height: 24),
                          _buildCategoryChanges(isDark),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetChangeCard(bool isDark, Color primaryColor) {
    final isLower = _currentMonthTotal < _previousMonthTotal;
    final diff = (_previousMonthTotal - _currentMonthTotal).abs();
    final pct = _previousMonthTotal > 0
        ? (diff / _previousMonthTotal * 100).round()
        : 0;

    final prevMonth = DateFormat(
      'MMMM',
    ).format(DateTime(DateTime.now().year, DateTime.now().month - 1));

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
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isLower ? Colors.green : Colors.red).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET CHANGE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: isDark
                                ? Colors.grey[500]
                                : const Color(0xFF94a3b8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isLower ? 'Lower' : 'Higher',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isLower
                                    ? const Color(0xFF10b981)
                                    : const Color(0xFFef4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spending is ${isLower ? 'lower' : 'higher'} than $prevMonth',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isLower ? Colors.green : Colors.red).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isLower
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isLower
                          ? const Color(0xFF10b981)
                          : const Color(0xFFef4444),
                      size: 26,
                    ),
                  ),
                ],
              ),
              if (_previousMonthTotal > 0) ...[
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[100]!,
                  height: 28,
                ),
                Row(
                  children: [
                    Icon(
                      isLower ? Icons.check_circle_rounded : Icons.info_rounded,
                      size: 16,
                      color: isLower
                          ? const Color(0xFF10b981)
                          : const Color(0xFFf59e0b),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLower
                          ? 'You saved ${_currencyFormat.format(diff)} vs last month'
                          : 'You spent ${_currencyFormat.format(diff)} more vs last month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLower
                            ? const Color(0xFF10b981)
                            : const Color(0xFFf59e0b),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(bool isDark, Color primaryColor) {
    final maxAmount = _monthlyData.isEmpty
        ? 1.0
        : _monthlyData.map((m) => m.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LAST 6 MONTHS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: isDark ? Colors.grey[500] : const Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(height: 20),
          // Bar area (fixed height, labels below)
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthlyData.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                final ratio = maxAmount > 0 ? m.amount / maxAmount : 0.0;
                final barH = 110 * ratio.toDouble();
                final isActive = m.isCurrent || _tappedMonthIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _tappedMonthIndex = (_tappedMonthIndex == i) ? null : i;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            height: barH,
                            decoration: BoxDecoration(
                              color: m.isCurrent
                                  ? primaryColor
                                  : _tappedMonthIndex == i
                                  ? primaryColor.withValues(alpha: 0.65)
                                  : primaryColor.withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, -2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          // Tooltip floating above – clip.none lets it overflow upward freely
                          if (isActive)
                            Positioned(
                              bottom: barH + 4,
                              child: AnimatedOpacity(
                                opacity: isActive ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.grey[850] ??
                                        const Color(0xFF1e293b),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _currencyFormat.format(m.amount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),
          // Month labels in their own row, always below the chart
          Row(
            children: _monthlyData.map((m) {
              return Expanded(
                child: Text(
                  m.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: m.isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: m.isCurrent
                        ? (isDark ? Colors.white : const Color(0xFF0f172a))
                        : (isDark ? Colors.grey[500] : const Color(0xFF94a3b8)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100]!,
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(primaryColor, 'Current Month'),
              const SizedBox(width: 20),
              _buildLegendDot(
                primaryColor.withValues(alpha: 0.25),
                'Previous Months',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChanges(bool isDark) {
    if (_topCategoryChanges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'TOP CATEGORY CHANGES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.grey[500],
            ),
          ),
        ),
        ..._topCategoryChanges.map(
          (delta) => _buildCategoryDeltaCard(delta, isDark),
        ),
      ],
    );
  }

  Widget _buildCategoryDeltaCard(_CategoryDelta delta, bool isDark) {
    final isSaved = delta.currentAmount <= delta.previousAmount;
    final diff = (delta.previousAmount - delta.currentAmount).abs();
    final color = ColorHelper.fromHex(delta.category.colorHex);
    final icon = IconHelper.getIcon(delta.category.iconName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delta.category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currencyFormat.format(delta.previousAmount)} → ${_currencyFormat.format(delta.currentAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : const Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isSaved ? '-' : '+'}${_currencyFormat.format(diff)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSaved
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSaved
                      ? const Color(0xFF10b981).withValues(alpha: 0.1)
                      : const Color(0xFFef4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSaved ? 'Saved' : 'Over',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSaved
                        ? const Color(0xFF10b981)
                        : const Color(0xFFef4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthData {
  final String label;
  final double amount;
  final bool isCurrent;

  _MonthData({
    required this.label,
    required this.amount,
    this.isCurrent = false,
  });
}

class _CategoryDelta {
  final Category category;
  final double currentAmount;
  final double previousAmount;

  _CategoryDelta({
    required this.category,
    required this.currentAmount,
    required this.previousAmount,
  });

  double get absoluteChange => (currentAmount - previousAmount).abs();
}
