import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';
import '../database/services/loan_service.dart';
import '../database/services/iou_service.dart';
import '../database/services/user_service.dart';
import '../models/loan.dart';
import '../models/iou.dart';
import '../utils/loan_calculator.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  bool _isInstitutional = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _lenderController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _tenureType = 'Yrs';
  String _interestType = 'reducing';
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateEMI);
    _interestRateController.addListener(_updateEMI);
    _tenureController.addListener(_updateEMI);
  }

  void _updateEMI() {
    setState(() {});
  }

  LoanCalculationResult _getLoanCalculation() {
    final principal = double.tryParse(_amountController.text) ?? 0.0;
    final rate = double.tryParse(_interestRateController.text) ?? 0.0;
    final tenureValue = int.tryParse(_tenureController.text) ?? 0;
    return LoanCalculator.calculate(
      LoanCalculationInput(
        principal: principal,
        annualRate: rate,
        tenureValue: tenureValue,
        tenureUnit: _tenureType,
        interestType: _interestType,
      ),
    );
  }

  String _formatCurrency(double amount, {int decimalDigits = 0}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: context.read<ProfileProvider>().currencySymbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  String _calculateEMI() {
    final result = _getLoanCalculation();
    if (!result.isValid) {
      return '${context.read<ProfileProvider>().currencySymbol}0';
    }
    return _formatCurrency(result.emi);
  }

  String _calculateTotalInterest() {
    final result = _getLoanCalculation();
    if (!result.isValid) {
      return '${context.read<ProfileProvider>().currencySymbol}0';
    }
    return _formatCurrency(result.totalInterest);
  }

  String _calculateTotalPayable() {
    final result = _getLoanCalculation();
    if (!result.isValid) {
      final principal = double.tryParse(_amountController.text) ?? 0.0;
      return _formatCurrency(principal);
    }
    return _formatCurrency(result.totalPayable);
  }

  final LoanService _loanService = LoanService();
  final IOUService _iouService = IOUService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _saveLoan() async {
    if (_amountController.text.isEmpty || _lenderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    if (_isInstitutional && _tenureController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter tenure to calculate total repayment details',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _userService.getCurrentUser();
      if (user != null && user.userId != null) {
        if (_isInstitutional) {
          final calculation = _getLoanCalculation();
          final principalAmount = double.parse(_amountController.text);
          final loan = Loan(
            userId: user.userId!,
            lenderName: _lenderController.text,
            loanType: 'Institutional',
            principalAmount: principalAmount,
            interestRate: double.tryParse(_interestRateController.text) ?? 0.0,
            interestType: _interestType,
            tenureValue: int.tryParse(_tenureController.text),
            tenureUnit: _tenureType == 'Yrs' ? 'years' : 'months',
            tenureMonths: calculation.tenureMonths,
            startDate: _startDate,
            dueDate: _tenureController.text.isNotEmpty
                ? _startDate.add(
                    Duration(
                      days:
                          (int.tryParse(_tenureController.text) ?? 0) *
                          (_tenureType == 'Yrs' ? 365 : 30),
                    ),
                  )
                : _startDate.add(const Duration(days: 365)),
            estimatedEmi: calculation.emi,
            estimatedTotalInterest: calculation.totalInterest,
            estimatedTotalPayable: calculation.isValid
                ? calculation.totalPayable
                : principalAmount,
            status: 'active',
            notes: _notesController.text,
            createdAt: DateTime.now(),
          );

          final profileId = mounted
              ? context.read<ProfileProvider>().activeProfileId
              : null;
          await _loanService.createLoan(loan, profileId: profileId);
        } else {
          final iou = IOU(
            userId: user.userId!,
            creditorName: _lenderController.text,
            amount: double.parse(_amountController.text),
            estimatedTotalPayable: double.parse(_amountController.text),
            dueDate: _startDate, // Used as due date in UI
            status: 'active',
            notes: _notesController.text,
            createdAt: DateTime.now(),
          );

          final profileId = mounted
              ? context.read<ProfileProvider>().activeProfileId
              : null;
          await _iouService.createIOU(iou, profileId: profileId);
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
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
    _lenderController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _notesController.dispose();
    super.dispose();
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? const Color(0xFFe5e7eb)
                              : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'Add New Loan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Type Toggle
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1e293b).withOpacity(0.5)
                                : const Color(0xFFe2e8f0).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton(
                                  'Institutional',
                                  _isInstitutional,
                                  () => setState(() => _isInstitutional = true),
                                  isDark,
                                ),
                              ),
                              Expanded(
                                child: _buildTypeButton(
                                  'Personal IOU',
                                  !_isInstitutional,
                                  () =>
                                      setState(() => _isInstitutional = false),
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Amount Input
                        Column(
                          children: [
                            Text(
                              'LOAN AMOUNT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: isDark
                                    ? const Color(0xFF94a3b8)
                                    : const Color(0xFF94a3b8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  context
                                      .read<ProfileProvider>()
                                      .currencySymbol,
                                  style: TextStyle(
                                    fontSize: 32,
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
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0f172a),
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      hintText: '0',
                                      hintStyle: TextStyle(
                                        color: Color(
                                          0xFFcbd5e1,
                                        ), // Matches light mode placeholder
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

                        const SizedBox(height: 32),

                        if (_isInstitutional) ...[
                          // Lender Details
                          _buildSectionContainer(
                            title: 'LENDER DETAILS',
                            child: TextField(
                              controller: _lenderController,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                              ),
                              decoration: _getInputDecoration(
                                hint: 'E.g. HDFC, SBI, or Name',
                                isDark: isDark,
                              ),
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          // Loan Terms
                          _buildSectionContainer(
                            title: 'LOAN TERMS',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 4,
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          'Interest Rate',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF94a3b8),
                                          ),
                                        ),
                                      ),
                                      Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          TextField(
                                            controller: _interestRateController,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d*'),
                                              ),
                                            ],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0f172a),
                                            ),
                                            decoration:
                                                _getInputDecoration(
                                                  hint: '0.0',
                                                  isDark: isDark,
                                                ).copyWith(
                                                  contentPadding:
                                                      const EdgeInsets.fromLTRB(
                                                        14,
                                                        14,
                                                        30,
                                                        14,
                                                      ),
                                                ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 14),
                                            child: Text(
                                              '%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF94a3b8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 4,
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          'Tenure',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF94a3b8),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF1e293b,
                                                ).withOpacity(0.5)
                                              : const Color(0xFFf8fafc),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _tenureController,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0f172a),
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      hintText: '0',
                                                      hintStyle: TextStyle(
                                                        color: Color(
                                                          0xFF94a3b8,
                                                        ),
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 14,
                                                          ),
                                                      isDense: true,
                                                    ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _tenureType =
                                                      _tenureType == 'Yrs'
                                                      ? 'Mos'
                                                      : 'Yrs';
                                                });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                child: Text(
                                                  _tenureType,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF64748b),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          _buildSectionContainer(
                            title: 'INTEREST TYPE',
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1e293b).withOpacity(0.5)
                                    : const Color(0xFFe2e8f0).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTypeButton(
                                      'Reducing',
                                      _interestType == 'reducing',
                                      () => setState(
                                        () => _interestType = 'reducing',
                                      ),
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTypeButton(
                                      'Flat',
                                      _interestType == 'flat',
                                      () => setState(
                                        () => _interestType = 'flat',
                                      ),
                                      isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          // Repayment (Institutional)
                          _buildSectionContainer(
                            title: 'REPAYMENT',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFf97316,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.calendar_month_rounded,
                                            color: Color(0xFFf97316),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Start Date',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0f172a),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'First EMI Date',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF94a3b8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        CustomDatePicker.show(
                                          context,
                                          initialDate: _startDate,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _startDate = date;
                                            });
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1e293b)
                                              : const Color(0xFFf8fafc),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFe2e8f0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(_startDate),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? const Color(0xFFcbd5e1)
                                                    : const Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.expand_more_rounded,
                                              size: 16,
                                              color: Color(0xFF94a3b8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withOpacity(isDark ? 0.1 : 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ESTIMATED MONTHLY EMI',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: Color(0xFF166534),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Based on rate & tenure',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF64748b),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              _calculateEMI(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: isDark
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : const Color(0xFF15803d),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total Interest',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748b),
                                                  ),
                                                ),
                                                Text(
                                                  _calculateTotalInterest(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total You Will Repay',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF166534),
                                                  ),
                                                ),
                                                Text(
                                                  _calculateTotalPayable(),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF166534),
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
                              ],
                            ),
                            isDark: isDark,
                          ),
                        ] else ...[
                          // Personal IOU Form

                          // Person Details
                          _buildSectionContainer(
                            title: 'PERSON DETAILS',
                            child: TextField(
                              controller: _lenderController,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                              ),
                              decoration:
                                  _getInputDecoration(
                                    hint: 'Search contact or enter name',
                                    isDark: isDark,
                                  ).copyWith(
                                    suffixIcon: Icon(
                                      Icons.person_search_rounded,
                                      color: isDark
                                          ? const Color(0xFF94a3b8)
                                          : const Color(0xFF64748b),
                                    ),
                                  ),
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          // Notes
                          _buildSectionContainer(
                            title: 'NOTES',
                            child: TextField(
                              controller: _notesController,
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                              ),
                              decoration: _getInputDecoration(
                                hint: 'Add a note regarding this loan...',
                                isDark: isDark,
                              ),
                            ),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          // Repayment (Personal)
                          _buildSectionContainer(
                            title: 'REPAYMENT',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFf97316,
                                            ).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today_rounded,
                                            color: Color(0xFFf97316),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            const Text(
                                              'Full payment due',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF94a3b8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: () {
                                        CustomDatePicker.show(
                                          context,
                                          initialDate: _startDate,
                                          onDateSelected: (date) {
                                            setState(() {
                                              _startDate = date;
                                            });
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1e293b)
                                              : const Color(0xFFf8fafc),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFe2e8f0),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(_startDate),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? const Color(0xFFcbd5e1)
                                                    : const Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.edit_calendar_rounded,
                                              size: 16,
                                              color: Color(0xFF94a3b8),
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
                                    color: Theme.of(context).colorScheme.primary
                                        .withOpacity(isDark ? 0.1 : 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
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
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748b),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatCurrency(
                                          double.tryParse(
                                                _amountController.text,
                                              ) ??
                                              0.0,
                                        ),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : const Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveLoan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save Loan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
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
                            Icon(Icons.check_rounded, size: 20),
                        ],
                      ),
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

  Widget _buildTypeButton(
    String title,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1a2c26) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0f172a))
                  : (isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withOpacity(0.5)
              : const Color(0xFFf1f5f9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration({
    required String hint,
    required bool isDark,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94a3b8)),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1e293b).withOpacity(0.5)
          : const Color(0xFFf8fafc),
      contentPadding: const EdgeInsets.all(14),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }
}
