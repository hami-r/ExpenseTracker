import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../database/services/data_management_service.dart';
import '../database/services/category_service.dart';
import '../models/category.dart';
import '../widgets/custom_date_picker.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  final DataManagementService _dataManagementService = DataManagementService();

  // State
  String _fileFormat = 'csv'; // 'csv' or 'xlsx'
  String _dateRangeType = 'all_time'; // 'all_time' or 'custom'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Filters & Sorting
  SortOption _sortOption = SortOption.dateDesc;
  List<Category> _categories = [];
  final List<int> _selectedCategoryIds = []; // Empty means all
  bool _isLoadingCategories = true;

  // Options
  bool _includeItemizedDetails = true;
  bool _includePaymentMethod = true;
  bool _includeNotes = false;
  bool _includeSummary = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      // Assuming user_id 1 for now as per existing pattern
      final categories = await CategoryService().getAllCategories(1);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2bb961);
    final scaffoldBg = isDark
        ? const Color(0xFF131f17)
        : const Color(0xFFf6f8f7);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final subTextColor = isDark
        ? const Color(0xFF94a3b8)
        : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF475569),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Export Report',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Format Section
                      _buildSectionTitle('File Format', isDark),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormatOption(
                              'CSV File',
                              'csv',
                              Icons.description_outlined,
                              const Color(0xFF10b981), // Emerald
                              isDark,
                              surfaceColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormatOption(
                              'Excel (XLSX)',
                              'xlsx',
                              Icons.table_view_outlined,
                              const Color(0xFF3b82f6), // Blue
                              isDark,
                              surfaceColor,
                              textColor,
                              subTextColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Date Range Section
                      _buildSectionTitle('Select Date Range', isDark),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
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
                            _buildDateRangeOption(
                              'All Time',
                              'all_time',
                              Icons.history,
                              Colors.purple,
                              isDark,
                              textColor,
                              subTextColor,
                            ),
                            _buildDateRangeOption(
                              'Custom Range',
                              'custom',
                              Icons.date_range,
                              Colors.orange,
                              isDark,
                              textColor,
                              subTextColor,
                            ),

                            if (_dateRangeType == 'custom') ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDatePickerField(
                                        'Start Date',
                                        _startDate,
                                        (date) =>
                                            setState(() => _startDate = date),
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDatePickerField(
                                        'End Date',
                                        _endDate,
                                        (date) =>
                                            setState(() => _endDate = date),
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const SizedBox(height: 32),

                      // Filters & Sorting Section
                      _buildSectionTitle('Filters & Sorting', isDark),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
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
                            _buildSortOption(isDark, textColor, subTextColor),
                            _buildDivider(isDark),
                            _buildCategoryFilter(
                              isDark,
                              textColor,
                              subTextColor,
                              primaryColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Options Section
                      _buildSectionTitle('Options', isDark),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
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
                            // Select All Option
                            _buildOptionItem(
                              'Select All',
                              'Include all details',
                              Icons.done_all,
                              _includeItemizedDetails &&
                                  _includePaymentMethod &&
                                  _includeNotes,
                              (val) {
                                setState(() {
                                  _includeItemizedDetails = val;
                                  _includePaymentMethod = val;
                                  _includeNotes = val;
                                });
                              },
                              isDark,
                              textColor,
                              subTextColor,
                            ),
                            _buildDivider(isDark),

                            // Individual Options
                            _buildOptionItem(
                              'Itemized Details',
                              'Split expense items',
                              Icons.list_alt,
                              _includeItemizedDetails,
                              (val) =>
                                  setState(() => _includeItemizedDetails = val),
                              isDark,
                              textColor,
                              subTextColor,
                            ),
                            _buildDivider(isDark),
                            _buildOptionItem(
                              'Payment Method',
                              'Show account names',
                              Icons.credit_card,
                              _includePaymentMethod,
                              (val) =>
                                  setState(() => _includePaymentMethod = val),
                              isDark,
                              textColor,
                              subTextColor,
                            ),
                            _buildDivider(isDark),
                            _buildOptionItem(
                              'Include Notes',
                              'Add transaction context',
                              Icons.description,
                              _includeNotes,
                              (val) => setState(() => _includeNotes = val),
                              isDark,
                              textColor,
                              subTextColor,
                            ),
                            if (_fileFormat == 'xlsx') ...[
                              _buildDivider(isDark),
                              _buildOptionItem(
                                'Include Summary Table',
                                'Add category totals sheet',
                                Icons.summarize,
                                _includeSummary,
                                (val) => setState(() => _includeSummary = val),
                                isDark,
                                textColor,
                                subTextColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Button
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleGenerateReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: primaryColor.withValues(alpha: 0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.download_rounded),
                                SizedBox(width: 8),
                                Text(
                                  'Generate Report',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Report will be ready to share promptly',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color subTextColor,
  ) {
    final isSelected = _fileFormat == value;
    final primaryColor = const Color(0xFF2bb961);

    return GestureDetector(
      onTap: () => setState(() => _fileFormat = value),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.05)
              : surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
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
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == 'csv'
                        ? 'Best for analysis'
                        : 'Formatted w/ styles',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Selection Indicator (Top Right)
            if (isSelected)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeOption(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final isSelected = _dateRangeType == value;
    final primaryColor = const Color(0xFF2bb961);

    return InkWell(
      onTap: () => setState(() => _dateRangeType = value),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    value == 'all_time'
                        ? 'Export complete history'
                        : 'Select specific dates',
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                  width: 2,
                ),
                color: isSelected ? primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    Function(DateTime) onSelect,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94a3b8),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            CustomDatePicker.show(
              context,
              initialDate: date,
              onDateSelected: onSelect,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.5)
                  : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFe2e8f0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.5)
                  : const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF64748b), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2bb961),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(bool isDark, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sort, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Order of transactions',
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          DropdownButton<SortOption>(
            value: _sortOption,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: subTextColor),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              DropdownMenuItem(
                value: SortOption.dateDesc,
                child: Text('Date (Newest First)'),
              ),
              DropdownMenuItem(
                value: SortOption.dateAsc,
                child: Text('Date (Oldest First)'),
              ),
              DropdownMenuItem(
                value: SortOption.amountHighLow,
                child: Text('Amount (High to Low)'),
              ),
              DropdownMenuItem(
                value: SortOption.amountLowHigh,
                child: Text('Amount (Low to High)'),
              ),
            ],
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                setState(() => _sortOption = newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    bool isDark,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
  ) {
    String subtitle = _selectedCategoryIds.isEmpty
        ? 'All categories selected'
        : '${_selectedCategoryIds.length} categories selected';

    return InkWell(
      onTap: _showCategoryFilterDialog,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Categories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subTextColor),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Select Categories',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.maxFinite,
                      height: 400,
                      child: ListView(
                        children: [
                          CheckboxListTile(
                            title: Text(
                              'Select All',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            value: _selectedCategoryIds.isEmpty,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedCategoryIds.clear();
                                }
                              });
                              setState(() {});
                            },
                          ),
                          const Divider(),
                          ..._categories.map((category) {
                            final isSelected =
                                _selectedCategoryIds.isEmpty ||
                                _selectedCategoryIds.contains(
                                  category.categoryId,
                                );

                            return CheckboxListTile(
                              title: Text(
                                category.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              value: isSelected,
                              activeColor: const Color(0xFF2bb961),
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    // If previously empty (all were selected), user is now selecting one.
                                    // So we should add current one to list?
                                    // Logic:
                                    // If list is empty -> All selected.
                                    // If I uncheck "Select All", I want to start with empty selection?
                                    // Actually, better logic:
                                    // If list is empty (All), and I uncheck a specific category,
                                    // I should populate list with all EXCEPT that one.
                                    if (_selectedCategoryIds.isEmpty) {
                                      _selectedCategoryIds.addAll(
                                        _categories.map((c) => c.categoryId!),
                                      );
                                      _selectedCategoryIds.remove(
                                        category.categoryId,
                                      );
                                    } else {
                                      _selectedCategoryIds.add(
                                        category.categoryId!,
                                      );
                                    }
                                  } else {
                                    // User unchecking
                                    if (_selectedCategoryIds.isEmpty) {
                                      // All are selected. Unchecking one.
                                      _selectedCategoryIds.addAll(
                                        _categories.map((c) => c.categoryId!),
                                      );
                                      _selectedCategoryIds.remove(
                                        category.categoryId,
                                      );
                                    } else {
                                      _selectedCategoryIds.remove(
                                        category.categoryId,
                                      );
                                    }
                                  }

                                  // Simplified logic attempt:
                                  // User taps category:
                                  // If currently showing as selected:
                                  //   De-select it.
                                  //   If list was empty (All), populate with all except this one.
                                  //   If list was not empty, remove this one.
                                  // If currently showing as un-selected:
                                  //   Select it. Add to list.
                                  //   If list now contains all categories, clear list (back to All).

                                  bool currentlySelected =
                                      _selectedCategoryIds.isEmpty ||
                                      _selectedCategoryIds.contains(
                                        category.categoryId,
                                      );

                                  if (currentlySelected) {
                                    // Deselecting
                                    if (_selectedCategoryIds.isEmpty) {
                                      _selectedCategoryIds.addAll(
                                        _categories.map((c) => c.categoryId!),
                                      );
                                    }
                                    _selectedCategoryIds.remove(
                                      category.categoryId,
                                    );
                                  } else {
                                    // Selecting
                                    _selectedCategoryIds.add(
                                      category.categoryId!,
                                    );
                                  }

                                  // If all selected explicitly, clear list to indicate 'All'
                                  if (_selectedCategoryIds.length ==
                                      _categories.length) {
                                    _selectedCategoryIds.clear();
                                  }
                                });
                                setState(() {});
                              },
                            );
                          }),
                        ],
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : const Color(0xFFf1f5f9),
    );
  }

  Future<void> _handleGenerateReport() async {
    setState(() => _isLoading = true);

    try {
      final filePath = await _dataManagementService.exportReport(
        format: _fileFormat == 'xlsx' ? ExportFormat.excel : ExportFormat.csv,
        startDate: _dateRangeType == 'custom' ? _startDate : null,
        endDate: _dateRangeType == 'custom' ? _endDate : null,
        includeItemizedDetails: _includeItemizedDetails,
        includePaymentMethod: _includePaymentMethod,
        includeNotes: _includeNotes,
        sortOption: _sortOption,
        selectedCategoryIds: _selectedCategoryIds,
        includeSummary: _includeSummary,
      );

      if (mounted) {
        _showSuccessDialog(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String filePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0f172a);

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: const Color(0xFF2bb961),
              ),
              const SizedBox(height: 16),
              Text(
                'Report Generated!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path.basename(filePath),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _dataManagementService.saveFileToDevice(filePath);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File saved to device'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save to Device'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(filePath)],
                            text: 'Expense Report',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2bb961),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
