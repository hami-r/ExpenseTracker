import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../models/payment_method.dart';
import '../utils/color_helper.dart';
import '../utils/icon_helper.dart';

class PaymentCorrelationScreen extends StatefulWidget {
  const PaymentCorrelationScreen({super.key});

  @override
  State<PaymentCorrelationScreen> createState() =>
      _PaymentCorrelationScreenState();
}

class _PaymentCorrelationScreenState extends State<PaymentCorrelationScreen> {
  final PaymentMethodService _pmService = PaymentMethodService();
  final UserService _userService = UserService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final NumberFormat _fmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _isLoading = true;

  List<_MethodSummary> _methodSummaries = [];
  List<_CategorySplit> _categorySplits = [];
  _MethodSummary? _topMethod;
  String _insightText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    if (user == null || !mounted) return;

    final db = await _dbHelper.database;
    final now = DateTime.now();
    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String().split('T')[0];
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
      0,
    ).toIso8601String().split('T')[0];
    final lastMonthStart = DateTime(
      now.year,
      now.month - 1,
      1,
    ).toIso8601String().split('T')[0];
    final lastMonthEnd = DateTime(
      now.year,
      now.month,
      0,
    ).toIso8601String().split('T')[0];

    // 1. Spending per payment method this month
    final pmRows = await db.rawQuery(
      '''
      SELECT pm.payment_method_id, pm.name, pm.type, pm.icon_name, pm.color_hex,
             COALESCE(SUM(t.amount), 0) AS total,
             COUNT(t.transaction_id) AS tx_count
      FROM payment_methods pm
      LEFT JOIN transactions t ON pm.payment_method_id = t.payment_method_id
        AND t.user_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
        AND t.parent_transaction_id IS NULL
      WHERE pm.user_id = ? AND pm.is_active = 1
      GROUP BY pm.payment_method_id
      HAVING total > 0
      ORDER BY total DESC
    ''',
      [user.userId, monthStart, monthEnd, user.userId],
    );

    // Last month totals per method for % change
    final lastMonthRows = await db.rawQuery(
      '''
      SELECT payment_method_id, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE user_id = ?
        AND transaction_date >= ?
        AND transaction_date <= ?
        AND parent_transaction_id IS NULL
      GROUP BY payment_method_id
    ''',
      [user.userId, lastMonthStart, lastMonthEnd],
    );

    final Map<int, double> lastMonthByMethod = {
      for (final r in lastMonthRows)
        (r['payment_method_id'] as int): (r['total'] as num).toDouble(),
    };

    final methods = await _pmService.getAllPaymentMethods(user.userId!);

    final List<_MethodSummary> summaries = [];
    for (final row in pmRows) {
      final pmId = row['payment_method_id'] as int;
      final total = (row['total'] as num).toDouble();
      final lastTotal = lastMonthByMethod[pmId] ?? 0;
      final pct = lastTotal > 0
          ? ((total - lastTotal) / lastTotal * 100).round()
          : null;
      final pm = methods.firstWhere(
        (m) => m.paymentMethodId == pmId,
        orElse: () => PaymentMethod(
          paymentMethodId: pmId,
          userId: user.userId!,
          name: row['name'] as String,
          type: row['type'] as String? ?? '',
        ),
      );
      summaries.add(
        _MethodSummary(
          method: pm,
          total: total,
          txCount: (row['tx_count'] as int? ?? 0),
          pctChange: pct,
        ),
      );
    }
    summaries.sort((a, b) => b.total.compareTo(a.total));

    // 2. Top categories and their per-method breakdown
    final catRows = await db.rawQuery(
      '''
      SELECT c.category_id, c.name, c.icon_name, c.color_hex,
             t.payment_method_id,
             COALESCE(SUM(t.amount), 0) AS total
      FROM categories c
      INNER JOIN transactions t ON c.category_id = t.category_id
      WHERE t.user_id = ?
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
        AND t.parent_transaction_id IS NULL
      GROUP BY c.category_id, t.payment_method_id
      ORDER BY total DESC
    ''',
      [user.userId, monthStart, monthEnd],
    );

    // Build category → method totals map
    final Map<int, _CategorySplit> catMap = {};
    for (final row in catRows) {
      final catId = row['category_id'] as int;
      final pmId = row['payment_method_id'] as int?;
      final total = (row['total'] as num).toDouble();
      if (!catMap.containsKey(catId)) {
        catMap[catId] = _CategorySplit(
          categoryId: catId,
          name: row['name'] as String,
          iconName: row['icon_name'] as String?,
          colorHex: row['color_hex'] as String? ?? '#888888',
          totalByMethod: {},
        );
      }
      if (pmId != null) {
        catMap[catId]!.totalByMethod[pmId] =
            (catMap[catId]!.totalByMethod[pmId] ?? 0) + total;
      }
    }

    // Sort categories by total spend
    final cats = catMap.values.toList()
      ..sort((a, b) => b.grandTotal.compareTo(a.grandTotal));

    // 3. AI-style insight: find the category + method with biggest ratio vs next method
    String insight = '';
    if (summaries.length >= 2 && cats.isNotEmpty) {
      final topCat = cats.first;
      double maxRatio = 0;
      String? insightCat, insightMethod1, insightMethod2;
      double mult = 0;

      for (final cat in cats) {
        final entries = cat.totalByMethod.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (entries.length >= 2) {
          final r = entries[0].value / entries[1].value;
          if (r > maxRatio) {
            maxRatio = r;
            insightCat = cat.name;
            final m1 = summaries.firstWhere(
              (s) => s.method.paymentMethodId == entries[0].key,
              orElse: () => summaries.first,
            );
            final m2 = summaries.firstWhere(
              (s) => s.method.paymentMethodId == entries[1].key,
              orElse: () => summaries.last,
            );
            insightMethod1 = m1.method.name;
            insightMethod2 = m2.method.name;
            mult = r;
          }
        }
      }

      if (insightCat != null) {
        insight =
            'You spend ${mult.toStringAsFixed(1)}x more on $insightCat when using $insightMethod1 compared to $insightMethod2.';
      } else {
        insight =
            '${topCat.name} is your biggest expense category this month using ${summaries.isNotEmpty ? summaries.first.method.name : 'your primary payment method'}.';
      }
    } else if (summaries.isNotEmpty) {
      insight =
          '${summaries.first.method.name} is your most used payment method this month.';
    }

    if (mounted) {
      setState(() {
        _methodSummaries = summaries;
        _topMethod = summaries.isNotEmpty ? summaries.first : null;
        _categorySplits = cats.take(5).toList();
        _insightText = insight;
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
                      'Payment Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _methodSummaries.isEmpty
                  ? _buildEmptyState(isDark)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_topMethod != null)
                            _buildHeroCard(isDark, primaryColor),
                          const SizedBox(height: 20),
                          _buildMethodCards(isDark),
                          const SizedBox(height: 20),
                          if (_categorySplits.isNotEmpty)
                            _buildCategorySplit(isDark),
                          const SizedBox(height: 20),
                          if (_insightText.isNotEmpty)
                            _buildInsightCard(isDark),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 56,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet this month',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see payment insights.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isDark, Color primaryColor) {
    final top = _topMethod!;
    final icon = IconHelper.getIcon(top.method.iconName);
    final color = top.method.colorHex != null
        ? ColorHelper.fromHex(top.method.colorHex!)
        : primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(28),
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
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOST USED MODE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      top.method.name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (top.pctChange != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (top.pctChange! >= 0
                                      ? Colors.green
                                      : primaryColor)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${top.pctChange! >= 0 ? '+' : ''}${top.pctChange}% vs last month',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: top.pctChange! >= 0
                                ? Colors.green
                                : primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PAYMENT METHODS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.grey[500],
            ),
          ),
        ),
        ...(_methodSummaries.take(6).map((s) => _buildMethodCard(s, isDark))),
      ],
    );
  }

  Widget _buildMethodCard(_MethodSummary s, bool isDark) {
    final icon = IconHelper.getIcon(s.method.iconName);
    final color = s.method.colorHex != null
        ? ColorHelper.fromHex(s.method.colorHex!)
        : Colors.grey;

    // Determine frequency label
    final freq = s.txCount >= 20
        ? 'Very High Frequency'
        : s.txCount >= 10
        ? 'High Frequency'
        : s.txCount >= 5
        ? 'Moderate'
        : 'Low Frequency';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.method.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  freq,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmt.format(s.total),
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

  Widget _buildCategorySplit(bool isDark) {
    // Color palette for methods (up to 6)
    final methodColors = [
      const Color(0xFF10b981),
      const Color(0xFFf59e0b),
      const Color(0xFF3b82f6),
      const Color(0xFFa855f7),
      const Color(0xFFef4444),
      const Color(0xFF06b6d4),
    ];

    // Map method index to color
    final methodIds = _methodSummaries
        .map((s) => s.method.paymentMethodId!)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(28),
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
            'CATEGORY SPLIT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ..._categorySplits.map((cat) {
            final total = cat.grandTotal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      Text(
                        _fmt.format(total),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: methodIds.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pmId = entry.value;
                          final amt = cat.totalByMethod[pmId] ?? 0;
                          final pct = total > 0 ? amt / total : 0.0;
                          if (pct == 0) return const SizedBox.shrink();
                          return Expanded(
                            flex: (pct * 1000).round(),
                            child: Container(
                              color: methodColors[idx % methodColors.length],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100]!,
            height: 1,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _methodSummaries.asMap().entries.take(6).map((entry) {
              final idx = entry.key;
              final s = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: methodColors[idx % methodColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    s.method.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e1a35) : const Color(0xFFf5f3ff),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4c1d95).withValues(alpha: 0.4)
              : const Color(0xFFddd6fe),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF4c1d95).withValues(alpha: 0.4)
                  : const Color(0xFFede9fe),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: isDark ? const Color(0xFFc4b5fd) : const Color(0xFF7c3aed),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSIGHT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: isDark
                        ? const Color(0xFFc4b5fd).withValues(alpha: 0.7)
                        : const Color(0xFF7c3aed).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _insightText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFede9fe)
                        : const Color(0xFF4c1d95),
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

// Data models
class _MethodSummary {
  final PaymentMethod method;
  final double total;
  final int txCount;
  final int? pctChange;

  _MethodSummary({
    required this.method,
    required this.total,
    required this.txCount,
    required this.pctChange,
  });
}

class _CategorySplit {
  final int categoryId;
  final String name;
  final String? iconName;
  final String colorHex;
  final Map<int, double> totalByMethod;

  _CategorySplit({
    required this.categoryId,
    required this.name,
    this.iconName,
    required this.colorHex,
    required this.totalByMethod,
  });

  double get grandTotal => totalByMethod.values.fold(0.0, (a, b) => a + b);
}
