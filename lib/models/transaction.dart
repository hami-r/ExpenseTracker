class Transaction {
  final int? transactionId;
  final int userId;
  final int? categoryId;
  final int? paymentMethodId;
  final double amount;
  final int currencyId;
  final String? note;
  final DateTime transactionDate;
  final bool isSplit;
  final int? parentTransactionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.transactionId,
    required this.userId,
    this.categoryId,
    this.paymentMethodId,
    required this.amount,
    this.currencyId = 1,
    this.note,
    required this.transactionDate,
    this.isSplit = false,
    this.parentTransactionId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'user_id': userId,
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'currency_id': currencyId,
      'note': note,
      'transaction_date': transactionDate.toIso8601String(),
      'is_split': isSplit ? 1 : 0,
      'parent_transaction_id': parentTransactionId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      transactionId: map['transaction_id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int?,
      paymentMethodId: map['payment_method_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      currencyId: map['currency_id'] as int? ?? 1,
      note: map['note'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      isSplit: (map['is_split'] as int?) == 1,
      parentTransactionId: map['parent_transaction_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Transaction copyWith({
    int? transactionId,
    int? userId,
    int? categoryId,
    int? paymentMethodId,
    double? amount,
    int? currencyId,
    String? note,
    DateTime? transactionDate,
    bool? isSplit,
    int? parentTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      currencyId: currencyId ?? this.currencyId,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      isSplit: isSplit ?? this.isSplit,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
