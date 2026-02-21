class Budget {
  final int? budgetId;
  final int userId;
  final int? categoryId; // Null means it's the overall/global budget
  final double amount;
  final int month;
  final int year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Budget({
    this.budgetId,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'budget_id': budgetId,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      budgetId: map['budget_id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Budget copyWith({
    int? budgetId,
    int? userId,
    int? categoryId,
    double? amount,
    int? month,
    int? year,
  }) {
    return Budget(
      budgetId: budgetId ?? this.budgetId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
