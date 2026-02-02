import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../utils/icon_helper.dart';
import '../utils/color_helper.dart';

class PaymentSelectionBottomSheet extends StatefulWidget {
  final List<PaymentMethod> paymentMethods;
  final int? selectedPaymentMethodId;
  final Function(PaymentMethod) onPaymentSelected;
  final VoidCallback onManageAccounts;

  const PaymentSelectionBottomSheet({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onPaymentSelected,
    required this.onManageAccounts,
  });

  @override
  State<PaymentSelectionBottomSheet> createState() =>
      _PaymentSelectionBottomSheetState();
}

class _PaymentSelectionBottomSheetState
    extends State<PaymentSelectionBottomSheet> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedPaymentMethodId;
  }

  Map<String, List<PaymentMethod>> _groupedMethods() {
    final Map<String, List<PaymentMethod>> grouped = {};
    for (var method in widget.paymentMethods) {
      if (!grouped.containsKey(method.type)) {
        grouped[method.type] = [];
      }
      grouped[method.type]!.add(method);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupedMethods = _groupedMethods();

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
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFe5e7eb),
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
                  if (widget.paymentMethods.isEmpty)
                    Center(
                      child: Text(
                        'No payment methods available',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b),
                        ),
                      ),
                    ),

                  ...groupedMethods.entries.map((entry) {
                    final type = entry.key;
                    final methods = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: isDark
                                ? const Color(0xFF64748b)
                                : const Color(0xFF94a3b8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...methods.map(
                          (method) => _buildMethodTile(
                            method,
                            isDark,
                            isSelected: _selectedId == method.paymentMethodId,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
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
                onPressed: widget.onManageAccounts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1e293b)
                      : const Color(0xFFf1f5f9),
                  foregroundColor: isDark
                      ? const Color(0xFFcbd5e1)
                      : const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Manage Accounts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(
    PaymentMethod method,
    bool isDark, {
    required bool isSelected,
  }) {
    final color = ColorHelper.fromHex(method.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? (isDark
                  ? const Color(0xFF2bb961).withOpacity(0.1)
                  : const Color(0xFF2bb961).withOpacity(0.05))
            : (isDark ? const Color(0xFF1a2c26) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedId = method.paymentMethodId;
            });
            widget.onPaymentSelected(method);
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
                    : (isDark
                          ? const Color(0xFF1e293b)
                          : const Color(0xFFf1f5f9)),
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
                        : (isDark
                              ? const Color(0xFF1e293b)
                              : color.withOpacity(0.1)),
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
                    IconHelper.getIcon(method.iconName),
                    size: 20,
                    color: isSelected
                        ? const Color(0xFF2bb961)
                        : (isDark ? color.withOpacity(0.8) : color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      if (method.accountNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          method.accountNumber!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF64748b)
                                : const Color(0xFF94a3b8),
                          ),
                        ),
                      ],
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
