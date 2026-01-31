import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/payment_selection_bottom_sheet.dart';
import '../widgets/custom_date_picker.dart';

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
  bool _isDeleteDialogVisible = false;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Food',
      'icon': Icons.lunch_dining_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': Colors.purple,
    },
    {
      'name': 'Charity',
      'icon': Icons.volunteer_activism_rounded,
      'color': Colors.red,
    },
    {'name': 'Housing', 'icon': Icons.cottage_rounded, 'color': Colors.teal},
    {
      'name': 'Fun',
      'icon': Icons.local_activity_rounded,
      'color': Colors.amber,
    },
    {'name': 'Education', 'icon': Icons.school_rounded, 'color': Colors.indigo},
    {'name': 'More', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'UPI (GPay Personal)',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Colors.white,
    },
    {
      'name': 'Cash',
      'icon': Icons.payments_rounded,
      'color': const Color(0xFF10b981),
    },
    {
      'name': 'Card (HDFC - 1234)',
      'icon': Icons.credit_card_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Bank',
      'icon': Icons.account_balance_rounded,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction['amount'] ?? '45.00',
    );
    _noteController = TextEditingController(
      text: widget.transaction['note'] ?? 'Lunch with friends',
    );

    // Parse date or default to now
    // In a real app, this would parse the date string. For now, just current date.
    _selectedDate = DateTime.now();

    // Find category index
    final categoryName = widget.transaction['category'];
    if (categoryName != null) {
      final index = categories.indexWhere((c) => c['name'] == categoryName);
      if (index != -1) _selectedCategoryIndex = index;
    }

    // Find payment method index
    final paymentMethodName = widget.transaction['paymentMethod'];
    if (paymentMethodName != null) {
      // Simple substring match or exact match depending on data
      if (paymentMethodName == 'Cash')
        _selectedPaymentIndex = 1;
      else if (paymentMethodName.contains('Card'))
        _selectedPaymentIndex = 2;
      else if (paymentMethodName == 'Bank')
        _selectedPaymentIndex = 3;
      else
        _selectedPaymentIndex = 0;
    }
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
                    primaryColor.withOpacity(isDark ? 0.1 : 0.4),
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
                    tertiaryColor.withOpacity(isDark ? 0.1 : 0.3),
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
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
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
                onPressed: () {
                  Navigator.pop(context); // Just back for now
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          if (_isDeleteDialogVisible) ...[
            // Dimmed background
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDeleteDialogVisible = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

            // Dialog
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value * 200),
                    child: child,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24).copyWith(bottom: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Delete Expense?',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Are you sure you want to delete this transaction?\nThis action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Perform delete action
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Close edit screen
                                Navigator.pop(
                                  context,
                                ); // Close details screen (if needed, or handle result)
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: Colors.red.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isDeleteDialogVisible = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        _isDeleteDialogVisible = true;
                      });
                    },
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 40),
            ],
          ),
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
                    '₹',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
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
                        ).colorScheme.onSurface.withOpacity(0.2),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
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
                onPressed: () {},
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategoryIndex == index;
              final isMore = category['name'] == 'More';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: isMore
                        ? Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                            style: BorderStyle.solid,
                            width: 1.5,
                          )
                        : isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : Border.all(color: Colors.transparent),
                    boxShadow: !isMore && !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                              color: isMore
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.05)
                                  : category['color'].withOpacity(
                                      isDark ? 0.2 : 0.1,
                                    ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              category['icon'],
                              size: 20,
                              color: isMore
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5)
                                  : (isDark
                                        ? category['color'].withOpacity(0.8)
                                        : category['color']),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isMore
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(0.6)
                                      : isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.6),
                                  letterSpacing: 0,
                                ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (isSelected && !isMore)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
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
              );
            },
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
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              final isSelected = _selectedPaymentIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  elevation: isSelected ? 8 : 0,
                  shadowColor: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
                      : Colors.black.withOpacity(0.05),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentIndex = index;
                      });
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => PaymentSelectionBottomSheet(
                          selectedPaymentMethod: method['name'],
                          onPaymentSelected: (accountName) {
                            // Handle account selection
                          },
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: !isSelected
                            ? Border.all(color: Colors.transparent)
                            : null,
                        boxShadow: !isSelected && !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            method['icon'],
                            size: 22,
                            color: isSelected ? Colors.white : method['color'],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            method['name'],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.4),
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
                        color: Colors.black.withOpacity(0.05),
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
                          ).colorScheme.onSurface.withOpacity(0.6),
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
                        ).colorScheme.onSurface.withOpacity(0.4),
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
                        color: Colors.black.withOpacity(0.05),
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
                    ).colorScheme.onSurface.withOpacity(0.6),
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
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Add a note...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
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
