import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  static void show(
    BuildContext context, {
    required DateTime initialDate,
    required Function(DateTime) onDateSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDatePicker(
        initialDate: initialDate,
        onDateSelected: onDateSelected,
      ),
    );
  }

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  final List<String> _weekDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + increment,
      );
    });
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstDayOffset(DateTime date) {
    // 0 = Sunday, 1 = Monday, etc. To match design where week starts on Sunday
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFe2e8f0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header (Month Navigation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _changeMonth(-1),
                  isDark: isDark,
                ),
                Text(
                  '${_months[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _changeMonth(1),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Weekdays Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekDays
                  .map(
                    (day) => SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94a3b8),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Days Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildDaysGrid(isDark, primaryColor),
          ),

          const SizedBox(height: 32),

          // Quick Select Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildQuickSelectButton(
                  'Today',
                  DateTime.now(),
                  isDark,
                  primaryColor,
                ),
                const SizedBox(width: 8),
                _buildQuickSelectButton(
                  'Yesterday',
                  DateTime.now().subtract(const Duration(days: 1)),
                  isDark,
                  primaryColor,
                ),
                const SizedBox(width: 8),
                _buildQuickSelectButton(
                  'Last 7 Days',
                  DateTime.now().subtract(const Duration(days: 7)),
                  isDark,
                  primaryColor,
                ),
              ],
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDateSelected(_selectedDate);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Bottom Safe Area
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF94a3b8)),
      ),
    );
  }

  Widget _buildDaysGrid(bool isDark, Color primaryColor) {
    final daysInMonth = _daysInMonth(_currentMonth);
    final firstDayOffset = _firstDayOffset(_currentMonth);
    final totalCells = daysInMonth + firstDayOffset;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - firstDayOffset + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 36, height: 36);
              }

              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: primaryColor, width: 1)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFcbd5e1)
                                  : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildQuickSelectButton(
    String label,
    DateTime date,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = label == "Today" && _isSameDay(date, _selectedDate);
    // Simple logic for quick selects highlighting. For "Last 7 Days" it might be a range, but for now treating as single date select/shortcut

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _currentMonth = DateTime(date.year, date.month);
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : (isDark
                    ? const Color(0xFF1e293b).withOpacity(0.5)
                    : const Color(0xFFf1f5f9)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: primaryColor.withOpacity(0.2))
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
          ),
        ),
      ),
    );
  }
}
