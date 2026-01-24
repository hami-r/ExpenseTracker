import 'package:flutter/material.dart';

class EditPaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentMethod;

  const EditPaymentMethodScreen({
    super.key,
    this.paymentMethod,
  });

  @override
  State<EditPaymentMethodScreen> createState() => _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  String _selectedType = 'Card';
  bool _isPrimary = false;
  String _linkedBank = 'HDFC Bank';
  Color _selectedCardColor = const Color(0xFF2bb961);
  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;

  final List<Map<String, dynamic>> methodTypes = [
    {'type': 'Card', 'icon': Icons.credit_card_rounded},
    {'type': 'Cash', 'icon': Icons.account_balance_wallet_rounded},
    {'type': 'Bank', 'icon': Icons.account_balance_rounded},
    {'type': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
  ];

  final List<Color> _cardColors = [
    const Color(0xFF2bb961), // Green
    const Color(0xFF3b82f6), // Blue
    const Color(0xFF9333ea), // Purple
    const Color(0xFF1f2937), // Black
    const Color(0xFFf97316), // Orange/Sunset
  ];

  final List<String> _indianBanks = [
    'HDFC Bank',
    'ICICI Bank',
    'State Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'IDBI Bank',
    'Yes Bank',
    'Bank of India',
    'Central Bank of India',
    'Indian Bank',
  ];

  bool get isEditMode => widget.paymentMethod != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.paymentMethod?['name'] ?? '',
    );
    _accountNumberController = TextEditingController();
    _ifscCodeController = TextEditingController();
    _selectedType = widget.paymentMethod?['type'] ?? 'Card';
    _isPrimary = widget.paymentMethod?['isPrimary'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        isEditMode ? 'Edit Payment Method' : 'Add Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Display with Title and Subtitle
                        Center(
                          child: Column(
                            children: [
                              // Show credit card for Card type, else show circular icon
                              if (_selectedType == 'Card') ...[
                                // Credit Card Design
                                Container(
                                  width: 288,
                                  height: 176,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _selectedCardColor,
                                        _selectedCardColor.withOpacity(0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _selectedCardColor.withOpacity(0.4),
                                        blurRadius: 35,
                                        offset: const Offset(0, 15),
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Decorative circles
                                      Positioned(
                                        top: -64,
                                        right: -64,
                                        child: Container(
                                          width: 160,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -40,
                                        left: -40,
                                        child: Container(
                                          width: 128,
                                          height: 128,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      // Card content
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Bank name and contactless icon
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'BANK NAME',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white.withOpacity(0.8),
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _nameController.text.isEmpty
                                                          ? 'HDFC Regalia'
                                                          : _nameController.text,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Icon(
                                                  Icons.contactless_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                            // Chip icon
                                            Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFfbbf24).withOpacity(0.9),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 24,
                                                      height: 2,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFb45309).withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Card number and logo
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _ifscCodeController.text.isEmpty
                                                      ? '**** 1234'
                                                      : '**** ${_ifscCodeController.text}',
                                                  style: const TextStyle(
                                                    fontSize: 21,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                    letterSpacing: 3,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                Text(
                                                  'VISA',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white.withOpacity(0.8),
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                ...[
                                  // Circular icon for other types
                                  Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Glow effect
                                      Container(
                                        width: 144,
                                        height: 144,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2bb961).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 128,
                                            height: 128,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: isDark
                                                    ? [
                                                        const Color(0xFF2c3035),
                                                        const Color(0xFF1f2327),
                                                      ]
                                                    : [
                                                        Colors.white,
                                                        const Color(0xFFf9fafb),
                                                      ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF131f17)
                                                    : const Color(0xFFf6f8f7),
                                                width: 6,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 30,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              methodTypes.firstWhere((m) => m['type'] == _selectedType)['icon'],
                                              size: 48,
                                              color: const Color(0xFF2bb961),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Checkmark badge
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2c3035) : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF131f17)
                                                  : const Color(0xFFf6f8f7),
                                              width: 4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Color(0xFF2bb961),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _nameController.text.isEmpty ? _getDefaultName() : _nameController.text,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF111827),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSubtitle(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Method Type
                        _buildLabel('Method Type', isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: methodTypes.map((method) {
                            final isSelected = _selectedType == method['type'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = method['type'];
                                });
                              },
                              child: Container(
                                width: (MediaQuery.of(context).size.width - 60) / 2,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2bb961).withOpacity(0.1)
                                      : (isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2bb961)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      method['icon'],
                                      size: 20,
                                      color: isSelected
                                          ? const Color(0xFF2bb961)
                                          : (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      method['type'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF2bb961)
                                            : (isDark ? Colors.white : const Color(0xFF111827)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Name/Label
                        _buildLabel(
                          _selectedType == 'Cash' ? 'Wallet Label' : '${_selectedType} Name / Label',
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2bb961),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            hintText: _getHintText(),
                            hintStyle: TextStyle(
                              color: (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)).withOpacity(0.5),
                            ),
                          ),
                        ),

                        // Card-specific fields
                        if (_selectedType == 'Card') ...[
                          const SizedBox(height: 24),
                          _buildLabel('Last 4 Digits', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ifscCodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2bb961),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              hintText: 'e.g., 1234',
                              hintStyle: TextStyle(
                                color: (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)).withOpacity(0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.password_rounded,
                                color: Color(0xFF2bb961),
                                size: 20,
                              ),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Card Skin', isDark),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _cardColors.map((color) {
                              final isSelected = _selectedCardColor == color;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCardColor = color;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: color.withOpacity(0.3),
                                            width: 4,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Bank-specific fields
                        if (_selectedType == 'Bank') ...[
                          const SizedBox(height: 24),
                          _buildLabel('Account Number', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2bb961),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              hintText: '•••• •••• •••• 4582',
                              hintStyle: TextStyle(
                                color: (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)).withOpacity(0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.numbers_rounded,
                                color: Color(0xFF2bb961),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('IFSC Code (Optional)', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ifscCodeController,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2bb961),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              hintText: 'e.g., SBIN0001543',
                              hintStyle: TextStyle(
                                color: (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)).withOpacity(0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.pin_rounded,
                                color: Color(0xFF2bb961),
                                size: 20,
                              ),
                            ),
                          ),
                        ],

                        // UPI-specific fields
                        if (_selectedType == 'UPI') ...[
                          const SizedBox(height: 24),
                          _buildLabel('UPI ID Label', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2bb961),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              hintText: 'e.g., user@okhdfcbank',
                              hintStyle: TextStyle(
                                color: (isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280)).withOpacity(0.5),
                              ),
                              prefixIcon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF2bb961),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLabel('Linked Bank', isDark),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _linkedBank,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2bb961),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                prefixIcon: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Color(0xFF2bb961),
                                  size: 20,
                                ),
                              ),
                              dropdownColor: isDark ? const Color(0xFF2c3035) : Colors.white,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF111827),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                              ),
                              items: _indianBanks.map((String bank) {
                                return DropdownMenuItem<String>(
                                  value: bank,
                                  child: Text(bank),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _linkedBank = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Set as Primary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF25282c) : const Color(0xFFf2f5f4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Set as primary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Default for new transactions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPrimary,
                                onChanged: (value) {
                                  setState(() {
                                    _isPrimary = value;
                                  });
                                },
                                activeColor: const Color(0xFF2bb961),
                              ),
                            ],
                          ),
                        ),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7)).withOpacity(0),
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7)),
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7)),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () {
                    // Save logic here
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2bb961),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: const Color(0xFF2bb961).withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isEditMode ? 'Save Changes' : 'Add Payment Method',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case 'Card':
        return 'e.g., HDFC Regalia';
      case 'Cash':
        return 'e.g., Physical Wallet';
      case 'Bank':
        return 'e.g., SBI Savings';
      case 'UPI':
        return 'e.g., GPay Personal';
      default:
        return 'Enter name';
    }
  }

  String _getDefaultName() {
    switch (_selectedType) {
      case 'Card':
        return 'Credit Card';
      case 'Cash':
        return 'Physical Wallet';
      case 'Bank':
        return 'Bank Account';
      case 'UPI':
        return 'UPI Method';
      default:
        return 'Payment Method';
    }
  }

  String _getSubtitle() {
    switch (_selectedType) {
      case 'Card':
        return 'Credit/Debit Card';
      case 'Cash':
        return 'Cash on Hand';
      case 'Bank':
        return 'Account ending in •••• 4582';
      case 'UPI':
        return 'Linked to $_linkedBank';
      default:
        return '';
    }
  }
}
