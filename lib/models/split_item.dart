class SplitItem {
  final int? splitItemId;
  final int transactionId;
  final String name;
  final int? categoryId;
  final double amount;
  final DateTime? createdAt;

  SplitItem({
    this.splitItemId,
    required this.transactionId,
    required this.name,
    this.categoryId,
    required this.amount,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'split_item_id': splitItemId,
      'transaction_id': transactionId,
      'name': name,
      'category_id': categoryId,
      'amount': amount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory SplitItem.fromMap(Map<String, dynamic> map) {
    return SplitItem(
      splitItemId: map['split_item_id'] as int?,
      transactionId: map['transaction_id'] as int,
      name: map['name'] as String,
      categoryId: map['category_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
