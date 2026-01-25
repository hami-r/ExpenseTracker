import 'package:flutter/material.dart';
import 'edit_payment_method_screen.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() =>
      _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState
    extends State<ManagePaymentMethodsScreen> {
  late List<Map<String, dynamic>> paymentMethods;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      paymentMethods = [
        {
          'name': 'Cash',
          'description': 'Default payment method',
          'icon': Icons.wallet_rounded,
          'color': Theme.of(context).colorScheme.primary,
          'isPrimary': true,
          'details': '',
        },
        {
          'name': 'Google Pay',
          'description': 'user@okhdfcbank',
          'icon': Icons.account_balance_wallet_rounded,
          'color': const Color(0xFF4285F4),
          'isPrimary': false,
          'details': '',
        },
        {
          'name': 'HDFC Regalia',
          'description': '•••• 1234',
          'icon': Icons.credit_card_rounded,
          'color': const Color(0xFF1e3a8a),
          'isPrimary': false,
          'details': 'Credit',
        },
        {
          'name': 'SBI Global',
          'description': '•••• 5678',
          'icon': Icons.contactless_rounded,
          'color': const Color(0xFF0284c7),
          'isPrimary': false,
          'details': 'Debit',
        },
        {
          'name': 'ICICI Net Banking',
          'description': 'Linked ••8892',
          'icon': Icons.account_balance_rounded,
          'color': const Color(0xFFea580c),
          'isPrimary': false,
          'details': '',
        },
      ];
      _isInitialized = true;
    }
  }

  void _deletePaymentMethod(int index, BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methodName = paymentMethods[index]['name'];

    if (paymentMethods[index]['isPrimary'] == true) {
      // Show error for primary method
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete primary payment method'),
          backgroundColor: isDark ? const Color(0xFFdc2626) : Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Payment Method',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$methodName"?',
            style: TextStyle(
              color: isDark ? const Color(0xFFd1d5db) : const Color(0xFF6b7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF6b7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        paymentMethods.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                  Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Add New Method Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditPaymentMethodScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Add New Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR METHODS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: isDark
                                ? const Color(0xFF64748b)
                                : const Color(0xFF66857d),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Payment Methods List
                    ...paymentMethods.asMap().entries.map((entry) {
                      return _buildPaymentCard(entry.value, entry.key, isDark);
                    }),

                    const SizedBox(height: 24),

                    // Bottom Note
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Swipe left on a card to reveal quick actions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (isDark
                                          ? const Color(0xFF6b7280)
                                          : const Color(0xFF9ca3af))
                                      .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Need help adding a card?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    Map<String, dynamic> method,
    int index,
    bool isDark,
  ) {
    final isPrimary = method['isPrimary'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2c3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
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
              gradient: LinearGradient(
                colors: isPrimary
                    ? [method['color'], method['color'].withOpacity(0.8)]
                    : [method['color'], method['color']],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: method['color'].withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(method['icon'], color: Colors.white, size: 24),
          ),

          const SizedBox(width: 16),

          // Name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        method['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary) ...{
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    },
                  ],
                ),
                if (method['details'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      method['details'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF60a5fa)
                            : const Color(0xFF2563eb),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  method['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF66857d),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditPaymentMethodScreen(paymentMethod: method),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF9ca3af),
                ),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFf3f4f6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              if (!isPrimary) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deletePaymentMethod(index, context),
                  icon: const Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: Color(0xFFef4444),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFef4444).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
