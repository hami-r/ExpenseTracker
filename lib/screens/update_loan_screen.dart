import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/loan.dart';
import '../models/loan_payment.dart';
import '../database/services/loan_service.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class UpdateLoanScreen extends StatefulWidget {
  final int loanId;
  const UpdateLoanScreen({super.key, required this.loanId});

  @override
  State<UpdateLoanScreen> createState() => _UpdateLoanScreenState();
}

class _UpdateLoanScreenState extends State<UpdateLoanScreen> {
  final LoanService _loanService = LoanService();
  Loan? _loan;
  bool _isLoading = true;

  int _monthsPaid = 0;
  int _initialMonthsPaid = 0;
  int _totalMonths = 60;
  final TextEditingController _extraPaymentController = TextEditingController();
  double _progressPercentage = 0.0;
  double _emi = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _extraPaymentController.addListener(_updateCalculations);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loan = await _loanService.getLoanById(widget.loanId);
      if (loan != null) {
        final totalMonths = loan.tenureUnit == 'years'
            ? (loan.tenureValue ?? 0) * 12
            : (loan.tenureValue ?? 0);

        // Progress should be principal-based (not EMI with interest), since
        // remaining amount and completion logic are principal-based.
        final monthlyPrincipal = totalMonths > 0
            ? (loan.principalAmount / totalMonths)
            : 0.0;
        final monthsPaid = monthlyPrincipal > 0
            ? (loan.totalPaid / monthlyPrincipal).floor().clamp(0, totalMonths)
            : 0;

        setState(() {
          _loan = loan;
          _totalMonths = totalMonths;
          _emi = monthlyPrincipal;
          _initialMonthsPaid = monthsPaid;
          _monthsPaid = monthsPaid;
          _progressPercentage = loan.principalAmount > 0
              ? (loan.totalPaid / loan.principalAmount * 100).clamp(0.0, 100.0)
              : 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading loan data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateCalculations() {
    if (_loan == null) return;
    final extraPayment = double.tryParse(_extraPaymentController.text) ?? 0;
    final newTotalPaid =
        _loan!.totalPaid +
        extraPayment +
        ((_monthsPaid - _initialMonthsPaid) * _emi);
    setState(() {
      _progressPercentage = _loan!.principalAmount > 0
          ? (newTotalPaid / _loan!.principalAmount * 100).clamp(0.0, 100.0)
          : 0.0;
    });
  }

  Future<void> _confirmUpdate() async {
    if (_loan == null) return;

    setState(() => _isLoading = true);
    try {
      double extraPayment = double.tryParse(_extraPaymentController.text) ?? 0;
      int monthsDiff = _monthsPaid - _initialMonthsPaid;
      double totalNewPayment =
          extraPayment + (monthsDiff > 0 ? monthsDiff * _emi : 0);

      if (totalNewPayment > 0) {
        // Create a payment log
        final payment = LoanPayment(
          loanId: _loan!.loanId!,
          paymentAmount: totalNewPayment,
          paymentDate: DateTime.now(),
          notes: extraPayment > 0 ? 'Extra principal + EMI' : 'EMI Payment',
        );
        await _loanService.createLoanPayment(payment);

        // Update total paid
        double newTotalPaid = _loan!.totalPaid + totalNewPayment;
        await _loanService.updateLoanTotalPaid(_loan!.loanId!, newTotalPaid);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _extraPaymentController.dispose();
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

          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loan == null
                ? const Center(child: Text('Loan not found'))
                : Column(
                    children: [
                      // Header
                      _buildHeader(context, isDark),

                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            children: [
                              // Loan badge
                              _buildLoanBadge(isDark),

                              const SizedBox(height: 24),

                              // Months paid counter
                              _buildMonthsCounter(isDark),

                              const SizedBox(height: 24),

                              // Extra payment
                              _buildExtraPayment(isDark),

                              const SizedBox(height: 32),

                              // Progress slider
                              _buildProgressSlider(isDark),

                              const SizedBox(height: 32),

                              // Impact summary
                              _buildImpactSummary(isDark),

                              const SizedBox(height: 100), // Space for button
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom button with gradient
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
                    (isDark ? const Color(0xFF131f17) : Colors.white)
                        .withOpacity(0),
                    isDark ? const Color(0xFF131f17) : Colors.white,
                    isDark ? const Color(0xFF131f17) : Colors.white,
                  ],
                  stops: const [0.0, 0.2, 1.0],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                40,
                24,
                32 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Confirm Update',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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
            'Update Loan Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildLoanBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 14,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          ),
          const SizedBox(width: 8),
          Text(
            '${_loan?.loanType == 'given' ? 'Given to' : 'Taken from'} • ${_loan?.lenderName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthsCounter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
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
        children: [
          Text(
            'MONTHS ALREADY PAID',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement button
              IconButton(
                onPressed: _monthsPaid > _initialMonthsPaid
                    ? () {
                        setState(() => _monthsPaid--);
                        _updateCalculations();
                      }
                    : null,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFf8fafc),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
              ),

              // Counter display
              SizedBox(
                width: 100,
                child: Text(
                  '$_monthsPaid',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
              ),

              // Increment button
              IconButton(
                onPressed: _monthsPaid < _totalMonths
                    ? () {
                        setState(() => _monthsPaid++);
                        _updateCalculations();
                      }
                    : null,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFf8fafc),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: isDark
                        ? const Color(0xFF94a3b8)
                        : const Color(0xFF64748b),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'out of $_totalMonths months',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraPayment(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF6366f1),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Extra Principal Payment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              TextField(
                controller: _extraPaymentController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFf8fafc),
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748b)
                        : const Color(0xFF94a3b8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFe2e8f0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFe2e8f0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 40,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    context.read<ProfileProvider>().currencySymbol,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied directly to principal amount.',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Current Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
            ),
            Text(
              '${_progressPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFe2e8f0),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _progressPercentage,
            min: 0,
            max: 100,
            onChanged:
                null, // Makes slider read-only visually since progress shouldn't be overridden explicitly here
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
              Text(
                '50%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF64748b),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.3)
            : const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFe2e8f0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMPACT SUMMARY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
          const SizedBox(height: 16),
          // Tenure
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFe2e8f0),
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Remaining Tenure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFcbd5e1)
                        : const Color(0xFF475569),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_totalMonths - _monthsPaid} Months',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    if (_totalMonths - _monthsPaid >= 0) ...[
                      const Text(
                        'Based on new amount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Interest savings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated Interest Savings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFcbd5e1)
                      : const Color(0xFF475569),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${context.read<ProfileProvider>().currencySymbol}${(_loan?.interestRate ?? 0) > 0 ? ((_loan?.principalAmount ?? 0) * (_loan?.interestRate ?? 0) / 100).toStringAsFixed(0) : "0"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10b981),
                    ),
                  ),
                  Text(
                    'Total estimated',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF94a3b8)
                          : const Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
