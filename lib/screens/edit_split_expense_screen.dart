import 'package:flutter/material.dart';

class EditSplitExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditSplitExpenseScreen({super.key, required this.transaction});

  @override
  State<EditSplitExpenseScreen> createState() => _EditSplitExpenseScreenState();
}

class _EditSplitExpenseScreenState extends State<EditSplitExpenseScreen> {
  final TextEditingController _totalAmountController = TextEditingController(
    text: '5,000',
  );

  // Example dummy data for split items
  final List<Map<String, dynamic>> _splitItems = [
    {
      'title': 'Groceries',
      'category': 'Food',
      'amount': '3,500',
      'icon': Icons.lunch_dining,
      'color': Colors.orange,
      'controller': TextEditingController(text: 'Groceries'),
      'amountController': TextEditingController(text: '3,500'),
    },
    {
      'title': 'T-shirt',
      'category': 'Shopping',
      'amount': '1,500',
      'icon': Icons.checkroom,
      'color': Colors.purple,
      'controller': TextEditingController(text: 'T-shirt'),
      'amountController': TextEditingController(text: '1,500'),
    },
  ];

  @override
  void dispose() {
    _totalAmountController.dispose();
    for (var item in _splitItems) {
      item['controller'].dispose();
      item['amountController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131f17)
        : const Color(0xFFf6f8f7);
    final surfaceColor = isDark ? const Color(0xFF1a2c26) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
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
                              '₹',
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
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
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
                            color: const Color(0xFF10b981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFF10b981),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '₹0.00 left to split',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10b981),
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
                              onPressed: () {},
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Split Items List
                        ..._splitItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSplitItemInput(
                              context,
                              isDark,
                              surfaceColor,
                              primaryColor,
                              item,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Payment Method Header
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Payment Method',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0f172a),
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPaymentOption(
                                context,
                                isDark,
                                'UPI (GPay Personal)',
                                Icons.qr_code_scanner_rounded,
                                isSelected: true,
                                primaryColor: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              _buildPaymentOption(
                                context,
                                isDark,
                                'Card (HDFC - 1234)',
                                Icons.credit_card_rounded,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildPaymentOption(
                                context,
                                isDark,
                                'Cash',
                                Icons.payments_rounded,
                                color: const Color(0xFF10b981),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Date
                        _buildSettingsRow(
                          context,
                          isDark,
                          surfaceColor,
                          Icons.calendar_today_rounded,
                          'DATE',
                          'Today, Oct 24',
                          hasArrow: true,
                        ),
                        const SizedBox(height: 12),
                        // Note
                        _buildSettingsRow(
                          context,
                          isDark,
                          surfaceColor,
                          Icons.edit_note_rounded,
                          null, // No label for note input style per design, just placeholder
                          null,
                          child: TextField(
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
                onPressed: () {
                  Navigator.pop(context); // close edit
                },
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
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.delete_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitItemInput(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Map<String, dynamic> item,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: item['color'], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: item['controller'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Item name',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748b)
                          : const Color(0xFF94a3b8),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (item['category'] as String).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94a3b8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94a3b8),
                  ),
                ),
                const SizedBox(width: 4),
                IntrinsicWidth(
                  child: TextField(
                    controller: item['amountController'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 40),
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

  Widget _buildPaymentOption(
    BuildContext context,
    bool isDark,
    String label,
    IconData icon, {
    bool isSelected = false,
    Color? color,
    Color? primaryColor,
  }) {
    final bgColor = isSelected
        ? (primaryColor ?? Colors.blue)
        : (isDark ? const Color(0xFF1a2c26) : Colors.white);
    final fgColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF475569));
    final iconColor = isSelected ? Colors.white : (color ?? fgColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ),
          if (!isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
            ),
          ],
        ],
      ),
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
