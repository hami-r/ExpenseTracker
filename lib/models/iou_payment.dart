class IOUPayment {
  final int? iouPaymentId;
  final int iouId;
  final double paymentAmount;
  final DateTime paymentDate;
  final int? paymentMethodId;
  final String? notes;
  final DateTime? createdAt;

  IOUPayment({
    this.iouPaymentId,
    required this.iouId,
    required this.paymentAmount,
    required this.paymentDate,
    this.paymentMethodId,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'iou_payment_id': iouPaymentId,
      'iou_id': iouId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_method_id': paymentMethodId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory IOUPayment.fromMap(Map<String, dynamic> map) {
    return IOUPayment(
      iouPaymentId: map['iou_payment_id'] as int?,
      iouId: map['iou_id'] as int,
      paymentAmount: (map['payment_amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMethodId: map['payment_method_id'] as int?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
