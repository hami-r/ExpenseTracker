import 'package:flutter/material.dart';

class PaymentSelectionBottomSheet extends StatefulWidget {
  final String selectedPaymentMethod;
  final Function(String) onPaymentSelected;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentSelected,
  });

  @override
  State<PaymentSelectionBottomSheet> createState() => _PaymentSelectionBottomSheetState();
}

class _PaymentSelectionBottomSheetState extends State<PaymentSelectionBottomSheet> {
  late String _selectedAccount;

  final List<Map<String, dynamic>> upiAccounts = [
    {
      'name': 'GPay Personal',
      'subtitle': '****@oksbi',
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xFF2bb961),
    },
    {
      'name': 'PhonePe',
      'subtitle': '****@ybl',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.indigo,
    },
  ];

  final List<Map<String, dynamic>> bankAccounts = [
    {
      'name': 'HDFC Bank',
      'subtitle': '**** 1234',
      'icon': Icons.account_balance_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'SBI Savings',
      'subtitle': '**** 5678',
      'icon': Icons.account_balance_rounded,
      'color': Colors.lightBlue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFe5e7eb),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Select Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // UPI Accounts
                  Text(
                    'UPI ACCOUNTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...upiAccounts.map((account) => _buildAccountTile(
                        account,
                        isDark,
                        isSelected: _selectedAccount == account['name'],
                      )),

                  const SizedBox(height: 24),

                  // Bank Accounts
                  Text(
                    'BANK ACCOUNTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...bankAccounts.map((account) => _buildAccountTile(
                        account,
                        isDark,
                        isSelected: _selectedAccount == account['name'],
                      )),
                ],
              ),
            ),
          ),

          // Manage Accounts Button
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1e293b).withOpacity(0.5)
                      : const Color(0xFFf8fafc),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9),
                  foregroundColor: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Manage Accounts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(Map<String, dynamic> account, bool isDark, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? (isDark ? const Color(0xFF2bb961).withOpacity(0.1) : const Color(0xFF2bb961).withOpacity(0.05))
            : (isDark ? const Color(0xFF1a2c26) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAccount = account['name'];
            });
            widget.onPaymentSelected(account['name']);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2bb961)
                    : (isDark ? const Color(0xFF1e293b) : const Color(0xFFf1f5f9)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF1e293b) : account['color'].withOpacity(0.1)),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    account['icon'],
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF2bb961)
                        : (isDark ? account['color'].withOpacity(0.8) : account['color']),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF64748b) : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SELECTED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: const Color(0xFF2bb961),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF2bb961),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
