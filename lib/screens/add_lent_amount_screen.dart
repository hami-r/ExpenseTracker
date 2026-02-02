import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_date_picker.dart';
import 'package:intl/intl.dart';
import '../database/services/receivable_service.dart';
import '../database/services/reimbursement_service.dart';
import '../database/services/user_service.dart';
import '../models/receivable.dart';
import '../models/reimbursement.dart';

class AddLentAmountScreen extends StatefulWidget {
  const AddLentAmountScreen({super.key});

  @override
  State<AddLentAmountScreen> createState() => _AddLentAmountScreenState();
}

class _AddLentAmountScreenState extends State<AddLentAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _interestController = TextEditingController(
    text: '0',
  );
  final TextEditingController _noteController = TextEditingController();
  DateTime? _expectedDate;
  int _selectedTypeIndex = 0; // 0 for Personal Lent, 1 for Reimbursement
  String _selectedCategory = 'Office';

  final ReceivableService _receivableService = ReceivableService();
  final ReimbursementService _reimbursementService = ReimbursementService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _saveLentAmount() async {
    if (_amountController.text.isEmpty || _recipientController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _userService.getCurrentUser();
      if (user != null && user.userId != null) {
        if (_selectedTypeIndex == 0) {
          // Personal Lent -> Receivable
          final receivable = Receivable(
            userId: user.userId!,
            recipientName: _recipientController.text,
            receivableType: 'Personal',
            principalAmount: double.parse(_amountController.text),
            interestRate: double.tryParse(_interestController.text) ?? 0.0,
            expectedDate: _expectedDate,
            status: 'active',
            notes: _noteController.text,
            createdAt: DateTime.now(),
          );
          await _receivableService.createReceivable(receivable);
        } else {
          // Reimbursement
          final reimbursement = Reimbursement(
            userId: user.userId!,
            sourceName: _recipientController.text,
            category: _selectedCategory,
            amount: double.parse(_amountController.text),
            expectedDate: _expectedDate,
            status: 'pending',
            notes: _noteController.text,
            createdAt: DateTime.now(),
          );
          await _reimbursementService.createReimbursement(reimbursement);
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      debugPrint('Error saving lent amount: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _interestController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    CustomDatePicker.show(
      context,
      initialDate: _expectedDate ?? DateTime.now(),
      onDateSelected: (DateTime picked) {
        setState(() {
          _expectedDate = picked;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                // Header
                _buildHeader(context, isDark),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Toggle Buttons
                        _buildTypeToggle(isDark),
                        const SizedBox(height: 32),

                        // Amount Input
                        _buildAmountInput(isDark),
                        const SizedBox(height: 32),

                        // Recipient Input
                        _buildInputLabel('Recipient / Item Name', isDark),
                        _buildRecipientInput(isDark),
                        const SizedBox(height: 16),

                        // Row: Interest & Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel(
                                    _selectedTypeIndex == 1
                                        ? 'Category'
                                        : 'Interest Rate',
                                    isDark,
                                  ),
                                  _buildInterestOrCategoryInput(isDark),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Expected By', isDark),
                                  _buildDateInput(context, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Note Input
                        _buildInputLabel('Add Note', isDark),
                        _buildNoteInput(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Button
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
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7))
                        .withOpacity(0),
                    (isDark
                        ? const Color(0xFF131f17)
                        : const Color(0xFFf6f8f7)),
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveLentAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Icon(Icons.check_circle_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Reimbursement',
                          style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
            'Add Reimbursement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 40), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildTypeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1e293b).withOpacity(0.5)
            : const Color(0xFFe2e8f0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTypeIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTypeIndex == 0
                      ? (isDark ? const Color(0xFF1a2c26) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTypeIndex == 0
                      ? Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFf1f5f9),
                        )
                      : null,
                  boxShadow: _selectedTypeIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Personal Lent',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTypeIndex == 0
                        ? (isDark ? Colors.white : const Color(0xFF0f172a))
                        : (isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTypeIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTypeIndex == 1
                      ? (isDark ? const Color(0xFF1a2c26) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTypeIndex == 1
                      ? Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFf1f5f9),
                        )
                      : null,
                  boxShadow: _selectedTypeIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Reimbursement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTypeIndex == 1
                        ? (isDark ? Colors.white : const Color(0xFF0f172a))
                        : (isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF64748b)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return Column(
      children: [
        Text(
          'TOTAL AMOUNT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isDark
                ? const Color(0xFF34d399)
                : const Color(0xFF059669).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.5)
                        : const Color(0xFFe2e8f0),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
        ),
      ),
    );
  }

  Widget _buildRecipientInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline_rounded,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFFcbd5e1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _recipientController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Amit S. or Dinner Bill',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFcbd5e1),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e293b) : const Color(0xFFf8fafc),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_rounded,
              size: 20,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFFcbd5e1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestOrCategoryInput(bool isDark) {
    if (_selectedTypeIndex == 1) {
      // Reimbursement -> Show Category Dropdown (Custom Button)
      return InkWell(
        onTap: () => _showCategoryModal(context, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFFcbd5e1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCategory,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFFcbd5e1),
              ),
            ],
          ),
        ),
      );
    }

    // Personal Lent -> Show Interest Input
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.percent_rounded,
            size: 20,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFFcbd5e1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _interestController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2c26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFFcbd5e1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _expectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_expectedDate!)
                    : '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0f172a),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Add a description or reason...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFcbd5e1),
          ),
        ),
      ),
    );
  }

  void _showCategoryModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFe2e8f0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 32,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCategoryOption(
                      Icons.apartment_rounded,
                      'Office',
                      const Color(0xFF10b981),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.flight_rounded,
                      'Travel',
                      const Color(0xFF0ea5e9),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.medical_services_rounded,
                      'Medical',
                      const Color(0xFFf43f5e),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.restaurant_rounded,
                      'Food',
                      const Color(0xFFf97316),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.currency_exchange_rounded,
                      'Refund',
                      const Color(0xFF8b5cf6),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.subscriptions_rounded,
                      'Subs',
                      const Color(0xFF6366f1),
                      isDark,
                    ),
                    _buildCategoryOption(
                      Icons.more_horiz_rounded,
                      'Others',
                      const Color(0xFF64748b),
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? color
                  : (isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b)),
            ),
          ),
        ],
      ),
    );
  }
}
