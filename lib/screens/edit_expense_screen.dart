import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/payment_selection_bottom_sheet.dart';
import '../widgets/custom_date_picker.dart';
import '../models/payment_method.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../utils/icon_helper.dart';
import '../utils/color_helper.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../database/services/transaction_service.dart';
import '../database/services/category_service.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'manage_payment_methods_screen.dart';
import 'manage_categories_screen.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditExpenseScreen({super.key, required this.transaction});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  int _selectedCategoryIndex = 0;
  int _selectedPaymentIndex = 0;

  late DateTime _selectedDate;

  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  final TransactionService _transactionService = TransactionService();

  List<PaymentMethod> _paymentMethods = [];
  List<Category> _categories = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction['amount']?.toString() ?? '0.00',
    );
    _noteController = TextEditingController(
      text: widget.transaction['note'] ?? 'Expense',
    );
    // Parse date safely
    try {
      if (widget.transaction['date'] is DateTime) {
        _selectedDate = widget.transaction['date'];
      } else {
        _selectedDate = DateTime.now();
      }
    } catch (e) {
      _selectedDate = DateTime.now();
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      if (!mounted) return;
      setState(() {
        _userId = user.userId;
      });

      final profileId = context.read<ProfileProvider>().activeProfileId;
      final results = await Future.wait([
        _categoryService.getAllCategories(user.userId!),
        _paymentMethodService.getAllPaymentMethods(
          user.userId!,
          profileId: profileId,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _paymentMethods = results[1] as List<PaymentMethod>;

          // Set initial category selection
          if (widget.transaction['categoryId'] != null) {
            final index = _categories.indexWhere(
              (c) => c.categoryId == widget.transaction['categoryId'],
            );
            if (index != -1) _selectedCategoryIndex = index;
          } else if (widget.transaction['category'] != null) {
            final index = _categories.indexWhere(
              (c) => c.name == widget.transaction['category'],
            );
            if (index != -1) _selectedCategoryIndex = index;
          }

          // Set initial payment method selection
          if (widget.transaction['paymentMethodId'] != null) {
            final index = _paymentMethods.indexWhere(
              (m) => m.paymentMethodId == widget.transaction['paymentMethodId'],
            );
            if (index != -1) _selectedPaymentIndex = index;
          } else if (widget.transaction['paymentMethod'] != null) {
            final index = _paymentMethods.indexWhere(
              (m) => m.name == widget.transaction['paymentMethod'],
            );
            if (index != -1) _selectedPaymentIndex = index;
          }
        });
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty || _userId == null) return;
    if (_categories.isEmpty || _paymentMethods.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final category = _categories[_selectedCategoryIndex];
    final paymentMethod = _paymentMethods[_selectedPaymentIndex];

    // We need the original ID to update.
    final transactionId = widget.transaction['id'] as int;

    // We can't easily parse the formatted date back to DateTime efficiently without year.
    // However, for an "Edit", we usually want to keep the original date unless changed.
    // The widget.transaction map doesn't have the raw DateTime.
    // This is a limitation of how we passed data.
    // Strategy: Fetch the original transaction to get the date, OR assume current date if new.
    // Better Strategy: Fetch the transaction by ID to get the full object including date.
    // Since we don't have it, we'll fetch it first.

    final originalTransaction = await _transactionService.getTransactionById(
      transactionId,
    );
    if (originalTransaction == null) return;
    if (!mounted) return;

    final updatedTransaction = model.Transaction(
      transactionId: transactionId,
      userId: _userId!,
      amount: amount,
      categoryId: category.categoryId!,
      paymentMethodId: paymentMethod.paymentMethodId!,
      transactionDate:
          _selectedDate, // We should update this to use CustomDatePicker result
      note: _noteController.text,
      isSplit: originalTransaction.isSplit,
      parentTransactionId: originalTransaction.parentTransactionId,
      createdAt: originalTransaction.createdAt,
    );

    final profileId = context.read<ProfileProvider>().activeProfileId;
    await _transactionService.updateTransaction(
      updatedTransaction,
      profileId: profileId,
    );
    if (!mounted) return;
    Navigator.pop(context, true); // Return true to indicate update
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background blobs
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
                    primaryColor.withValues(alpha: isDark ? 0.1 : 0.4),
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
                    tertiaryColor.withValues(alpha: isDark ? 0.1 : 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildAmountSection(isDark),
                        const SizedBox(height: 32),
                        _buildCategorySection(isDark),
                        const SizedBox(height: 32),
                        _buildPaymentMethodSection(isDark),
                        const SizedBox(height: 24),
                        _buildDetailsSection(isDark),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Save Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0),
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 48,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
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
            'Edit Expense',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAmountSection(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text('AMOUNT', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.read<ProfileProvider>().currencySymbol,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(bool isDark) {
    final hasCategories = _categories.isNotEmpty;
    final selectedIndex = hasCategories
        ? (_selectedCategoryIndex >= 0 &&
                  _selectedCategoryIndex < _categories.length
              ? _selectedCategoryIndex
              : 0)
        : -1;
    final selectedCategory = hasCategories ? _categories[selectedIndex] : null;
    const maxVisibleCategories = 8;
    final visibleCategories = _categories.take(maxVisibleCategories).toList();
    if (selectedCategory != null &&
        !visibleCategories.any(
          (category) => category.categoryId == selectedCategory.categoryId,
        )) {
      if (visibleCategories.length == maxVisibleCategories) {
        visibleCategories.removeLast();
      }
      visibleCategories.add(selectedCategory);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 14),
              ),
              TextButton(
                onPressed: () async {
                  final selectedCategory = await Navigator.push<Category>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ManageCategoriesScreen(isSelectionMode: true),
                    ),
                  );

                  if (selectedCategory != null && mounted) {
                    setState(() {
                      final index = _categories.indexWhere(
                        (c) => c.categoryId == selectedCategory.categoryId,
                      );
                      if (index != -1) {
                        _selectedCategoryIndex = index;
                      }
                    });
                  }
                },
                child: Text(
                  'See all',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedCategory != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ColorHelper.fromHex(
                        selectedCategory.colorHex,
                      ).withValues(alpha: isDark ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconHelper.getIcon(selectedCategory.iconName),
                      size: 18,
                      color: isDark
                          ? ColorHelper.fromHex(
                              selectedCategory.colorHex,
                            ).withValues(alpha: 0.9)
                          : ColorHelper.fromHex(selectedCategory.colorHex),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedCategory.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    'Selected',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 104,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: visibleCategories.length,
              itemBuilder: (context, index) {
                final category = visibleCategories[index];
                final isSelected =
                    selectedCategory != null &&
                    category.categoryId == selectedCategory.categoryId;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == visibleCategories.length - 1 ? 0 : 12,
                  ),
                  child: SizedBox(
                    width: 84,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final selectedOriginalIndex = _categories.indexWhere(
                            (c) => c.categoryId == category.categoryId,
                          );
                          if (selectedOriginalIndex != -1) {
                            _selectedCategoryIndex = selectedOriginalIndex;
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : Border.all(color: Colors.transparent),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: ColorHelper.fromHex(
                                      category.colorHex,
                                    ).withValues(alpha: isDark ? 0.2 : 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    IconHelper.getIcon(category.iconName),
                                    size: 20,
                                    color: isDark
                                        ? ColorHelper.fromHex(
                                            category.colorHex,
                                          ).withValues(alpha: 0.8)
                                        : ColorHelper.fromHex(
                                            category.colorHex,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    category.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurface
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                          letterSpacing: 0,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).cardTheme.color!,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 8,
                                    color: Colors.white,
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
                              ).colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
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
                        // Main selection area
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Modal trigger
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
                                selectedPaymentMethodId: method.paymentMethodId,
                                onPaymentSelected: (selectedMethod) {
                                  setState(() {
                                    final index = _paymentMethods.indexWhere(
                                      (m) =>
                                          m.paymentMethodId ==
                                          selectedMethod.paymentMethodId,
                                    );
                                    if (index != -1) {
                                      _selectedPaymentIndex = index;
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
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  CustomDatePicker.show(
                    context,
                    initialDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATE',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d').format(_selectedDate),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add a note...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
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
