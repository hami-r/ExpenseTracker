class Loan {
  final int? loanId;
  final int userId;
  final String lenderName;
  final String loanType;
  final double principalAmount;
  final double interestRate;
  final String interestType;
  final int? tenureValue;
  final String? tenureUnit;
  final int tenureMonths;
  final DateTime startDate;
  final DateTime? dueDate;
  final int? repaymentDayOfMonth;
  final double totalPaid;
  final double estimatedEmi;
  final double estimatedTotalInterest;
  final double estimatedTotalPayable;
  final String status;
  final String? notes;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Loan({
    this.loanId,
    required this.userId,
    required this.lenderName,
    required this.loanType,
    required this.principalAmount,
    this.interestRate = 0.0,
    this.interestType = 'reducing',
    this.tenureValue,
    this.tenureUnit,
    this.tenureMonths = 0,
    required this.startDate,
    this.dueDate,
    this.repaymentDayOfMonth,
    this.totalPaid = 0.0,
    this.estimatedEmi = 0.0,
    this.estimatedTotalInterest = 0.0,
    this.estimatedTotalPayable = 0.0,
    this.status = 'active',
    this.notes,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'user_id': userId,
      'lender_name': lenderName,
      'loan_type': loanType,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'interest_type': interestType,
      'tenure_value': tenureValue,
      'tenure_unit': tenureUnit,
      'tenure_months': tenureMonths,
      'start_date': startDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'repayment_day_of_month': repaymentDayOfMonth,
      'total_paid': totalPaid,
      'estimated_emi': estimatedEmi,
      'estimated_total_interest': estimatedTotalInterest,
      'estimated_total_payable': estimatedTotalPayable,
      'status': status,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      loanId: map['loan_id'] as int?,
      userId: map['user_id'] as int,
      lenderName: map['lender_name'] as String,
      loanType: map['loan_type'] as String,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
      interestType: (map['interest_type'] as String?) ?? 'reducing',
      tenureValue: map['tenure_value'] as int?,
      tenureUnit: map['tenure_unit'] as String?,
      tenureMonths: (map['tenure_months'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(map['start_date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      repaymentDayOfMonth: (map['repayment_day_of_month'] as num?)?.toInt(),
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,
      estimatedEmi: (map['estimated_emi'] as num?)?.toDouble() ?? 0.0,
      estimatedTotalInterest:
          (map['estimated_total_interest'] as num?)?.toDouble() ?? 0.0,
      estimatedTotalPayable:
          (map['estimated_total_payable'] as num?)?.toDouble() ??
          (map['principal_amount'] as num).toDouble(),
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      isDeleted: (map['is_deleted'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
