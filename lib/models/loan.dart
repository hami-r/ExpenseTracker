class Loan {
  final int? loanId;
  final int userId;
  final String lenderName;
  final String loanType;
  final double principalAmount;
  final double interestRate;
  final int? tenureValue;
  final String? tenureUnit;
  final DateTime startDate;
  final DateTime? dueDate;
  final double totalPaid;
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
    this.tenureValue,
    this.tenureUnit,
    required this.startDate,
    this.dueDate,
    this.totalPaid = 0.0,
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
      'tenure_value': tenureValue,
      'tenure_unit': tenureUnit,
      'start_date': startDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'total_paid': totalPaid,
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
      tenureValue: map['tenure_value'] as int?,
      tenureUnit: map['tenure_unit'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      totalPaid: (map['total_paid'] as num?)?.toDouble() ?? 0.0,
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
