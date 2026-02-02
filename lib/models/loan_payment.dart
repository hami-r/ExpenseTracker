class LoanPayment {
  final int? loanPaymentId;
  final int loanId;
  final double paymentAmount;
  final DateTime paymentDate;
  final int? paymentMethodId;
  final double? principalPart;
  final double? interestPart;
  final String? notes;
  final DateTime? createdAt;

  LoanPayment({
    this.loanPaymentId,
    required this.loanId,
    required this.paymentAmount,
    required this.paymentDate,
    this.paymentMethodId,
    this.principalPart,
    this.interestPart,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loan_payment_id': loanPaymentId,
      'loan_id': loanId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_method_id': paymentMethodId,
      'principal_part': principalPart,
      'interest_part': interestPart,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory LoanPayment.fromMap(Map<String, dynamic> map) {
    return LoanPayment(
      loanPaymentId: map['loan_payment_id'] as int?,
      loanId: map['loan_id'] as int,
      paymentAmount: (map['payment_amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMethodId: map['payment_method_id'] as int?,
      principalPart: (map['principal_part'] as num?)?.toDouble(),
      interestPart: (map['interest_part'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
