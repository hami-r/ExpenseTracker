import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../database/services/split_transaction_service.dart';
import '../../database/services/category_service.dart';
import '../../database/services/payment_method_service.dart';
import '../../models/transaction.dart' as model; // Alias to avoid conflict
import '../../models/split_item.dart';
import '../../models/category.dart';
import '../../models/payment_method.dart';
import '../../utils/icon_helper.dart';
import '../../utils/color_helper.dart';
import '../../providers/profile_provider.dart';
import 'package:expense_tracker_ai/widgets/custom_date_picker.dart';
import 'package:provider/provider.dart';
import 'add_split_item_screen.dart';
import '../../widgets/payment_selection_bottom_sheet.dart';
import 'manage_payment_methods_screen.dart';

class EditSplitExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditSplitExpenseScreen({super.key, required this.transaction});

  @override
  State<EditSplitExpenseScreen> createState() => _EditSplitExpenseScreenState();
}

class _EditSplitExpenseScreenState extends State<EditSplitExpenseScreen> {
  final SplitTransactionService _splitTransactionService =
      SplitTransactionService();
  final CategoryService _categoryService = CategoryService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();

  late TextEditingController _totalAmountController;
  late TextEditingController _noteController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _splitItems = [];
  Map<int, Category> _categoriesMap = {};
  List<PaymentMethod> _paymentMethods = [];
  int _selectedPaymentIndex = 0;
  double _totalAmount = 0.0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _totalAmount = widget.transaction['amount'] as double;
    _selectedDate = widget.transaction['date'] as DateTime;
    _totalAmountController = TextEditingController(
      text: _totalAmount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(
      text: widget.transaction['note'] as String? ?? '',
    );
    _loadData();

    _totalAmountController.addListener(_updateTotalAmount);
  }

  void _updateTotalAmount() {
    final text = _totalAmountController.text.replaceAll(',', '');
    setState(() {
      _totalAmount = double.tryParse(text) ?? 0.0;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactionId = widget.transaction['id'] as int;
      final userId = widget.transaction['userId'] as int?;
      final profileId = context.read<ProfileProvider>().activeProfileId;

      final results = await Future.wait([
        _splitTransactionService.getSplitItemsByTransaction(transactionId),
        if (userId != null)
          _categoryService.getAllCategories(userId)
        else
          Future.value(<Category>[]),
        if (userId != null)
          _paymentMethodService.getAllPaymentMethods(
            userId,
            profileId: profileId,
          )
        else
          Future.value(<PaymentMethod>[]),
      ]);

      if (mounted) {
        final splitItems = results[0] as List<SplitItem>;
        final categories = results[1] as List<Category>;
        final paymentMethods = results[2] as List<PaymentMethod>;

        // Create category map
        final categoriesMap = <int, Category>{};
        for (var cat in categories) {
          if (cat.categoryId != null) {
            categoriesMap[cat.categoryId!] = cat;
          }
        }

        // Convert SplitItems to mutable Maps for UI
        final uiSplitItems = splitItems.map((item) {
          final category = categoriesMap[item.categoryId];
          return {
            'id': item.splitItemId,
            'categoryId': item.categoryId,
            'controller': TextEditingController(text: item.name),
            'amountController': TextEditingController(
              text: item.amount.toStringAsFixed(0),
            ),
            'color': ColorHelper.fromHex(category?.colorHex),
            'icon': IconHelper.getIcon(category?.iconName),
            'categoryName': category?.name ?? 'Uncategorized',
          };
        }).toList();

        setState(() {
          _splitItems = uiSplitItems;
          _categoriesMap = categoriesMap;
          _paymentMethods = paymentMethods;

          if (_paymentMethods.isNotEmpty) {
            final existingId = widget.transaction['paymentMethodId'] as int?;
            if (existingId != null) {
              final idx = _paymentMethods.indexWhere(
                (m) => m.paymentMethodId == existingId,
              );
              _selectedPaymentIndex = idx != -1 ? idx : 0;
            } else {
              final primaryIdx = _paymentMethods.indexWhere((m) => m.isPrimary);
              _selectedPaymentIndex = primaryIdx != -1 ? primaryIdx : 0;
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading split data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _noteController.dispose();
    for (var item in _splitItems) {
      item['controller'].dispose();
      item['amountController'].dispose();
    }
    super.dispose();
  }

  double get _currentSplitTotal {
    double total = 0.0;
    for (var item in _splitItems) {
      final amountText = (item['amountController'] as TextEditingController)
          .text
          .replaceAll(',', '');
      total += double.tryParse(amountText) ?? 0.0;
    }
    return total;
  }

  double get _remainingAmount => _totalAmount - _currentSplitTotal;

  Future<void> _addNewItem() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddSplitItemScreen()),
    );

    if (result == null || !mounted) return;

    final selectedCategoryName = result['category'] as String?;
    int? categoryId;
    Category? matchedCategory;
    if (selectedCategoryName != null) {
      for (final entry in _categoriesMap.entries) {
        if (entry.value.name.toLowerCase() ==
            selectedCategoryName.toLowerCase()) {
          categoryId = entry.key;
          matchedCategory = entry.value;
          break;
        }
      }
    }
    matchedCategory ??= categoryId != null
        ? _categoriesMap[categoryId]
        : _categoriesMap.values.firstOrNull;

    setState(() {
      _splitItems.add({
        'id': null, // New item
        'categoryId': categoryId,
        'controller': TextEditingController(
          text: result['name']?.toString() ?? '',
        ),
        'amountController': TextEditingController(
          text: result['amount']?.toString() ?? '',
        ),
        'color': matchedCategory != null
            ? ColorHelper.fromHex(matchedCategory.colorHex)
            : (result['color'] as Color? ?? Colors.grey),
        'icon': matchedCategory != null
            ? IconHelper.getIcon(matchedCategory.iconName)
            : (result['icon'] as IconData? ?? Icons.category),
        'categoryName':
            matchedCategory?.name ?? (selectedCategoryName ?? 'Category'),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      // Don't dispose controller immediately if we want to undo (optional),
      // but for now strict remove
      final item = _splitItems.removeAt(index);
      (item['controller'] as TextEditingController).dispose();
      (item['amountController'] as TextEditingController).dispose();
    });
  }

  Future<void> _saveChanges() async {
    // Validate
    if ((_remainingAmount.abs() > 0.01)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total amount must match sum of split items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prepare Parent Transaction Update
      // We need to fetch the full transaction object to update it properly,
      // or at least construct one with the fields we have + existing ID.
      // Since we only edit Amount, Note, and Date here (and split items),
      // we should preserve other fields from the original widget.transaction
      // BUT `widget.transaction` is a Map, not the full object.
      // Ideally we should have fetched the full `Transaction` object.
      // For now, let's assume we update only what we can.
      // Actually, `SplitTransactionService.updateSplitTransaction` expects a `Transaction` object.

      // Let's create a Transaction object with the UPDATED values.
      // We need to be careful not to nullify other fields like paymentMethodId, categoryId (parent).

      final updatedTransaction = model.Transaction(
        transactionId: widget.transaction['id'] as int,
        userId: widget.transaction['userId'] as int,
        categoryId: widget.transaction['categoryId'] as int, // Parent category
        paymentMethodId: _paymentMethods.isNotEmpty
            ? _paymentMethods[_selectedPaymentIndex].paymentMethodId
            : (widget.transaction['paymentMethodId'] as int?),
        amount: _totalAmount,
        transactionDate: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        createdAt:
            DateTime.now(), // Won't change created_at in DB update usually
        isSplit: true,
      );

      // 2. Prepare Split Items
      final List<SplitItem> splitItems = _splitItems.map((item) {
        final amountText = (item['amountController'] as TextEditingController)
            .text
            .replaceAll(',', '');
        final amount = double.tryParse(amountText) ?? 0.0;

        return SplitItem(
          splitItemId: item['id'] as int?, // null for new items
          transactionId: updatedTransaction.transactionId!,
          name: (item['controller'] as TextEditingController).text,
          categoryId: item['categoryId'] as int?,
          amount: amount,
        );
      }).toList();

      // 3. Call Service
      final profileId = mounted
          ? context.read<ProfileProvider>().activeProfileId
          : null;
      await _splitTransactionService.updateSplitTransaction(
        updatedTransaction,
        splitItems,
        profileId: profileId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      debugPrint('Error saving split transaction: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131f17)
        : const Color(0xFFf6f8f7);
    final surfaceColor = isDark ? const Color(0xFF1a2c26) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final remaining = _remainingAmount;
    final isBalanced = remaining.abs() < 0.01;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Wrap body in GestureDetector to dismiss keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(isDark ? 0.1 : 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.tertiary.withOpacity(isDark ? 0.1 : 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          // Total Amount Section
                          Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF64748b)
                                  : const Color(0xFF94a3b8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                context.read<ProfileProvider>().currencySymbol,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFcbd5e1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: _totalAmountController,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0f172a),
                                    height: 1,
                                  ),
                                  decoration: const InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isBalanced
                                          ? const Color(0xFF10b981)
                                          : Colors.red)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBalanced
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_rounded,
                                  size: 16,
                                  color: isBalanced
                                      ? const Color(0xFF10b981)
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isBalanced
                                      ? 'Balanced'
                                      : '${context.read<ProfileProvider>().currencySymbol}${remaining.toStringAsFixed(2)} left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isBalanced
                                        ? const Color(0xFF10b981)
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Itemized Split Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Itemized Split',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0f172a),
                                    ),
                              ),
                              TextButton.icon(
                                onPressed: _addNewItem,
                                icon: Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  'Add Item',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Split Items List
                          if (_splitItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "No items. Add one to start splitting.",
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _splitItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildSplitItemInput(
                                  context,
                                  isDark,
                                  primaryColor,
                                  _splitItems[index],
                                  index,
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          // Payment Method
                          _buildPaymentMethodSection(isDark),

                          const SizedBox(height: 24),

                          // Date
                          GestureDetector(
                            onTap: () {
                              CustomDatePicker.show(
                                context,
                                initialDate: _selectedDate,
                                onDateSelected: (date) {
                                  setState(() {
                                    _selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      _selectedDate.hour,
                                      _selectedDate.minute,
                                      _selectedDate.second,
                                      _selectedDate.millisecond,
                                      _selectedDate.microsecond,
                                    );
                                  });
                                },
                              );
                            },
                            child: _buildSettingsRow(
                              context,
                              isDark,
                              surfaceColor,
                              Icons.calendar_today_rounded,
                              'DATE',
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              hasArrow: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Note
                          _buildSettingsRow(
                            context,
                            isDark,
                            surfaceColor,
                            Icons.edit_note_rounded,
                            null,
                            null,
                            child: TextField(
                              controller: _noteController,
                              decoration: InputDecoration(
                                hintText: 'Add a note...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF94a3b8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                              ),
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Save Button Footer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [backgroundColor.withOpacity(0), backgroundColor],
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
            'Edit Split Expense',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSplitItemInput(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Map<String, dynamic> item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.transparent),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
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
              color:
                  (item['color'] as Color?)?.withOpacity(isDark ? 0.2 : 0.1) ??
                  Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'] as IconData? ?? Icons.category,
              size: 20,
              color: isDark
                  ? (item['color'] as Color?)?.withOpacity(0.8)
                  : (item['color'] as Color?),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: item['controller'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Item name',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (item['categoryName'] as String? ?? 'CATEGORY').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.read<ProfileProvider>().currencySymbol,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 40,
                  child: TextField(
                    controller: item['amountController'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeItem(index),
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: Colors.red.withOpacity(0.7),
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Payment Method',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              final method = _paymentMethods[index];
              final isSelected = _selectedPaymentIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPaymentIndex = index;
                              });
                            },
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                top: 12,
                                bottom: 12,
                                right: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    IconHelper.getIcon(method.iconName),
                                    size: 22,
                                    color: isSelected
                                        ? Colors.white
                                        : ColorHelper.fromHex(method.colorHex),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    method.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPaymentIndex = index;
                              });
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => PaymentSelectionBottomSheet(
                                  paymentMethods: _paymentMethods,
                                  selectedPaymentMethodId:
                                      method.paymentMethodId,
                                  onPaymentSelected: (selectedMethod) {
                                    setState(() {
                                      final idx = _paymentMethods.indexWhere(
                                        (m) =>
                                            m.paymentMethodId ==
                                            selectedMethod.paymentMethodId,
                                      );
                                      if (idx != -1) {
                                        _selectedPaymentIndex = idx;
                                      }
                                    });
                                  },
                                  onManageAccounts: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ManagePaymentMethodsScreen(),
                                      ),
                                    );
                                    _loadData();
                                  },
                                ),
                              );
                            },
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 12,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.4),
                              ),
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
        ),
      ],
    );
  }

  Widget _buildSettingsRow(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    IconData icon,
    String? label,
    String? value, {
    bool hasArrow = false,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0f172a) : const Color(0xFFf1f5f9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                child ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94a3b8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      value ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ],
                ),
          ),
          if (hasArrow)
            Icon(Icons.chevron_right_rounded, color: const Color(0xFF94a3b8)),
        ],
      ),
    );
  }
}
