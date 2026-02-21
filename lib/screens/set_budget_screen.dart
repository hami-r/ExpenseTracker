import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../database/services/budget_service.dart';
import '../database/services/category_service.dart';
import 'manage_categories_screen.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';

class SetBudgetScreen extends StatefulWidget {
  final int userId;
  final int month;
  final int year;
  final List<Budget> existingBudgets;

  const SetBudgetScreen({
    super.key,
    required this.userId,
    required this.month,
    required this.year,
    required this.existingBudgets,
  });

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  bool _isLoading = true;

  final Map<int, TextEditingController> _categoryControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allCats = await _categoryService.getAllCategories(widget.userId);
      // Only add categories that already have a budget
      final activeCategories = <Category>[];

      for (var cat in allCats) {
        final b = widget.existingBudgets
            .where((b) => b.categoryId == cat.categoryId)
            .firstOrNull;

        if (b != null && b.amount > 0) {
          activeCategories.add(cat);
          final ctrl = TextEditingController(text: b.amount.toInt().toString());
          _categoryControllers[cat.categoryId!] = ctrl;
        }
      }

      if (mounted) {
        setState(() {
          _categories = activeCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading set budget data: $e');
    }
  }

  Future<void> _saveBudgets() async {
    // Save only category budgets

    final profileId = context.read<ProfileProvider>().activeProfileId;

    for (var cat in _categories) {
      final ctrl = _categoryControllers[cat.categoryId!];
      if (ctrl != null) {
        final valStr = ctrl.text.trim();
        if (valStr.isNotEmpty) {
          final val = double.tryParse(valStr);
          if (val != null && val >= 0) {
            await _budgetService.saveBudget(
              Budget(
                userId: widget.userId,
                profileId: profileId,
                categoryId: cat.categoryId,
                amount: val,
                month: widget.month,
                year: widget.year,
              ),
            );
          }
        }
      }
    }

    if (mounted) {
      Navigator.pop(context, true); // True implies changes were made
    }
  }

  @override
  void dispose() {
    for (var ctrl in _categoryControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      appBar: AppBar(
        title: const Text(
          'Set Budget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Limits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF30353E),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addNewCategoryLimit,
                      icon: Icon(Icons.add_rounded, color: primaryColor),
                      label: Text(
                        'Add Category',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._categories
                    .where((c) => c.categoryId != null)
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildInputCard(
                          isDark,
                          c.name,
                          Icons.category_rounded, // Use simple icon for speed
                          _categoryControllers[c.categoryId!]!,
                          primaryColor,
                        ),
                      ),
                    ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 32),
        child: ElevatedButton(
          onPressed: _saveBudgets,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Save Boundaries',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController controller,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : const Color(0xFF717782),
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF30353E),
                  ),
                  decoration: InputDecoration(
                    prefixText:
                        '${context.read<ProfileProvider>().currencySymbol} ',
                    prefixStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF30353E),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            onPressed: () {
              // Option to remove the category limit
              setState(() {
                final catId = _categoryControllers.entries
                    .firstWhere((e) => e.value == controller)
                    .key;
                _categories.removeWhere((c) => c.categoryId == catId);
                _categoryControllers.remove(catId);
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCategoryLimit() async {
    // Navigate to a selection screen and get a category back
    final selectedCategory = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ManageCategoriesScreen(isSelectionMode: true),
      ),
    );

    if (selectedCategory != null && selectedCategory.categoryId != null) {
      if (!_categories.any(
        (c) => c.categoryId == selectedCategory.categoryId,
      )) {
        setState(() {
          _categories.add(selectedCategory);
          _categoryControllers[selectedCategory.categoryId!] =
              TextEditingController();
        });
      }
    }
  }
}
