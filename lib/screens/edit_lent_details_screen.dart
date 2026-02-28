import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';
import '../models/receivable.dart';
import '../database/services/receivable_service.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';

class EditLentDetailsScreen extends StatefulWidget {
  final int receivableId;
  const EditLentDetailsScreen({super.key, required this.receivableId});

  @override
  State<EditLentDetailsScreen> createState() => _EditLentDetailsScreenState();
}

class _EditLentDetailsScreenState extends State<EditLentDetailsScreen> {
  final ReceivableService _receivableService = ReceivableService();
  Receivable? _receivable;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _expectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final receivable = await _receivableService.getReceivableById(
        widget.receivableId,
      );
      if (receivable != null) {
        if (mounted) {
          setState(() {
            _receivable = receivable;
            _amountController.text = receivable.principalAmount.toStringAsFixed(
              0,
            );
            _recipientController.text = receivable.recipientName;
            _interestController.text = receivable.interestRate.toStringAsFixed(
              2,
            );
            _noteController.text = receivable.notes ?? '';
            _expectedDate = receivable.expectedDate;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading receivable: $e');
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
                    ).colorScheme.primary.withValues(alpha: isDark ? 0.1 : 0.4),
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
                    Theme.of(context).colorScheme.tertiary.withValues(
                      alpha: isDark ? 0.1 : 0.3,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receivable == null
                ? const Center(child: Text('Receivable not found'))
                : Column(
                    children: [
                      _buildHeader(context, isDark),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              _buildAmountSection(isDark),
                              const SizedBox(height: 32),
                              _buildInputLabel('Recipient / Item Name', isDark),
                              _buildRecipientInput(isDark),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel(
                                          'Interest Rate',
                                          isDark,
                                        ),
                                        _buildInterestInput(isDark),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('Expected By', isDark),
                                        _buildDateInput(context, isDark),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                        .withValues(alpha: 0),
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
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: const Color(
                        0xFF2bb961,
                      ).withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
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
          // Common Arrow Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
          Text(
            'Edit Details',
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

  Widget _buildAmountSection(bool isDark) {
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
                : const Color(0xFF059669).withValues(alpha: 0.8),
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
                context.read<ProfileProvider>().currencySymbol,
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
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFe2e8f0),
                  ),
                ),
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildInterestInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Future<void> _saveChanges() async {
    if (_receivable == null) return;

    try {
      final updatedReceivable = Receivable(
        receivableId: _receivable!.receivableId,
        userId: _receivable!.userId,
        recipientName: _recipientController.text.trim(),
        receivableType: _receivable!.receivableType,
        principalAmount:
            double.tryParse(_amountController.text) ??
            _receivable!.principalAmount,
        interestRate:
            double.tryParse(_interestController.text) ??
            _receivable!.interestRate,
        expectedDate: _expectedDate,
        totalReceived: _receivable!.totalReceived,
        status: _receivable!.status,
        notes: _noteController.text.trim(),
        createdAt: _receivable!.createdAt,
        updatedAt: DateTime.now(),
      );

      final profileId = mounted
          ? context.read<ProfileProvider>().activeProfileId
          : null;
      await _receivableService.updateReceivable(
        updatedReceivable,
        profileId: profileId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      debugPrint('Error saving receivable: $e');
    }
  }
}
