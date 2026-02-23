import 'dart:math' as math;

class LoanCalculationInput {
  final double principal;
  final double annualRate;
  final int tenureValue;
  final String tenureUnit;
  final String interestType;

  const LoanCalculationInput({
    required this.principal,
    required this.annualRate,
    required this.tenureValue,
    required this.tenureUnit,
    this.interestType = 'reducing',
  });
}

class LoanCalculationResult {
  final bool isValid;
  final int tenureMonths;
  final double emi;
  final double totalInterest;
  final double totalPayable;

  const LoanCalculationResult({
    required this.isValid,
    required this.tenureMonths,
    required this.emi,
    required this.totalInterest,
    required this.totalPayable,
  });

  const LoanCalculationResult.invalid()
    : isValid = false,
      tenureMonths = 0,
      emi = 0,
      totalInterest = 0,
      totalPayable = 0;
}

class LoanCalculator {
  static String normalizeInterestType(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'flat') return 'flat';
    return 'reducing';
  }

  static String normalizeTenureUnit(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'yrs' ||
        normalized == 'yr' ||
        normalized == 'year' ||
        normalized == 'years' ||
        normalized == 'y') {
      return 'years';
    }
    return 'months';
  }

  static int toTenureMonths(int tenureValue, String tenureUnit) {
    if (tenureValue <= 0) return 0;
    return normalizeTenureUnit(tenureUnit) == 'years'
        ? tenureValue * 12
        : tenureValue;
  }

  static LoanCalculationResult calculate(LoanCalculationInput input) {
    final principal = input.principal;
    final annualRate = input.annualRate < 0 ? 0.0 : input.annualRate;
    final tenureMonths = toTenureMonths(input.tenureValue, input.tenureUnit);

    if (principal <= 0 || tenureMonths <= 0) {
      return const LoanCalculationResult.invalid();
    }

    if (annualRate <= 0) {
      final emi = principal / tenureMonths;
      return LoanCalculationResult(
        isValid: true,
        tenureMonths: tenureMonths,
        emi: emi,
        totalInterest: 0,
        totalPayable: principal,
      );
    }

    final interestType = normalizeInterestType(input.interestType);
    if (interestType == 'flat') {
      final totalInterest =
          principal * (annualRate / 100) * (tenureMonths / 12);
      final totalPayable = principal + totalInterest;
      final emi = totalPayable / tenureMonths;
      return LoanCalculationResult(
        isValid: true,
        tenureMonths: tenureMonths,
        emi: emi,
        totalInterest: totalInterest,
        totalPayable: totalPayable,
      );
    }

    final monthlyRate = annualRate / (12 * 100);
    final growthFactor = math.pow(1 + monthlyRate, tenureMonths).toDouble();
    final denominator = growthFactor - 1;
    if (denominator == 0) {
      final emi = principal / tenureMonths;
      return LoanCalculationResult(
        isValid: true,
        tenureMonths: tenureMonths,
        emi: emi,
        totalInterest: 0,
        totalPayable: principal,
      );
    }

    final emi = (principal * monthlyRate * growthFactor) / denominator;
    final totalPayable = emi * tenureMonths;
    final totalInterest = math.max(0.0, totalPayable - principal).toDouble();

    return LoanCalculationResult(
      isValid: true,
      tenureMonths: tenureMonths,
      emi: emi,
      totalInterest: totalInterest,
      totalPayable: totalPayable,
    );
  }
}
