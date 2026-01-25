import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class DetailedSpendingAnalyticsScreen extends StatefulWidget {
  const DetailedSpendingAnalyticsScreen({super.key});

  @override
  State<DetailedSpendingAnalyticsScreen> createState() => _DetailedSpendingAnalyticsScreenState();
}

class _DetailedSpendingAnalyticsScreenState extends State<DetailedSpendingAnalyticsScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1F2937) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDateRange() {
    final dateFormat = DateFormat('d MMM yyyy');
    return '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Travel',
        'amount': 898.0,
        'percentage': 62.32,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.flight_takeoff_rounded,
        'bgColor': const Color(0xFF8B5CF6).withOpacity(0.1),
      },
      {
        'name': 'Food',
        'amount': 488.0,
        'percentage': 33.87,
        'color': const Color(0xFFF43F5E),
        'icon': Icons.fastfood_rounded,
        'bgColor': const Color(0xFFF43F5E).withOpacity(0.1),
      },
      {
        'name': 'Charity',
        'amount': 32.0,
        'percentage': 2.22,
        'color': const Color(0xFF38BDF8),
        'icon': Icons.volunteer_activism_rounded,
        'bgColor': const Color(0xFF38BDF8).withOpacity(0.1),
      },
      {
        'name': 'Fuel',
        'amount': 23.0,
        'percentage': 1.60,
        'color': const Color(0xFFEAB308),
        'icon': Icons.local_gas_station_rounded,
        'bgColor': const Color(0xFFEAB308).withOpacity(0.1),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    'Expense Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Date Range Selector
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFd1d5db) : const Color(0xFF4b5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Donut Chart
            CustomPaint(
              size: const Size(288, 288),
              painter: DonutChartPainter(
                categories: categories,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 40),

            // Category List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryCard(category, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category['bgColor'],
              shape: BoxShape.circle,
            ),
            child: Icon(
              category['icon'],
              color: category['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '₹${category['amount'].toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: category['percentage'] / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: category['color'],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${category['percentage'].toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final bool isDark;

  DonutChartPainter({
    required this.categories,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;
    final strokeWidth = 24.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = (isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb)).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw segments
    double startAngle = -math.pi / 2; // Start from top

    for (final category in categories) {
      final sweepAngle = (category['percentage'] / 100) * 2 * math.pi;

      final paint = Paint()
        ..color = category['color']
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Center text
    final totalAmount = categories.fold<double>(0, (sum, cat) => sum + cat['amount']);
    
    // Draw "Total Amount" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Total Amount',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - 24),
    );

    // Draw total amount
    final amountPainter = TextPainter(
      text: TextSpan(
        text: '₹${totalAmount.toStringAsFixed(1)}',
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFF10b981),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    amountPainter.layout();
    amountPainter.paint(
      canvas,
      Offset(center.dx - amountPainter.width / 2, center.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
