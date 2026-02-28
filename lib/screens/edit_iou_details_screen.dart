import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';

import '../database/services/iou_service.dart';
import '../models/iou.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';

class EditIOUDetailsScreen extends StatefulWidget {
  final int iouId;
  const EditIOUDetailsScreen({super.key, required this.iouId});

  @override
  State<EditIOUDetailsScreen> createState() => _EditIOUDetailsScreenState();
}

class _EditIOUDetailsScreenState extends State<EditIOUDetailsScreen> {
  final IOUService _iouService = IOUService();
  IOU? _iou;
  bool _isLoading = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  DateTime _repaymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final iou = await _iouService.getIOUById(widget.iouId);
      if (iou != null) {
        setState(() {
          _iou = iou;
          _amountController.text = iou.amount.toStringAsFixed(0);
          _personController.text = iou.creditorName;
          _repaymentDate = iou.dueDate ?? DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error loading IOU data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_iou == null) return;

    try {
      final updatedAmount =
          double.tryParse(_amountController.text) ?? _iou!.amount;
      final updatedStatus = _iou!.totalPaid >= updatedAmount
          ? 'completed'
          : 'active';
      final updatedIOU = IOU(
        iouId: _iou!.iouId,
        userId: _iou!.userId,
        creditorName: _personController.text.trim(),
        amount: updatedAmount,
        estimatedTotalPayable: updatedAmount,
        dueDate: _repaymentDate,
        totalPaid: _iou!.totalPaid,
        status: updatedStatus,
        notes: _iou!.notes,
        createdAt: _iou!.createdAt,
        updatedAt: DateTime.now(),
      );

      final profileId = mounted
          ? context.read<ProfileProvider>().activeProfileId
          : null;
      await _iouService.updateIOU(updatedIOU, profileId: profileId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating IOU: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    CustomDatePicker.show(
      context,
      initialDate: _repaymentDate,
      onDateSelected: (DateTime picked) {
        if (picked != _repaymentDate) {
          setState(() {
            _repaymentDate = picked;
          });
        }
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
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      // Main Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                          child: Column(
                            children: [
                              // Amount Input
                              _buildAmountInput(isDark),

                              const SizedBox(height: 32),

                              // Form Fields
                              _buildPersonSection(isDark),
                              const SizedBox(height: 16),
                              _buildRepaymentSection(isDark),
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
              padding: const EdgeInsets.all(24),
              color: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_rounded, size: 20),
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
            'Edit Personal IOU',
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

  Widget _buildAmountInput(bool isDark) {
    return Column(
      children: [
        Text(
          'LOAN AMOUNT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF94a3b8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              context.read<ProfileProvider>().currencySymbol,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFcbd5e1),
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSON DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _personController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFf8fafc),
                  hintText: 'Search contact or enter name',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748b)
                        : const Color(0xFF94a3b8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.person_search_rounded,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.5)
              : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPAYMENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFfb923c).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFea580c),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repayment Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Full payment due',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF94a3b8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFe2e8f0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(_repaymentDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFcbd5e1)
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF94a3b8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TOTAL YOU WILL REPAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF166534),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Personal IOU (0% interest)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748b)),
                    ),
                  ],
                ),
                Text(
                  '${context.read<ProfileProvider>().currencySymbol}${(double.tryParse(_amountController.text) ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF166534),
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
