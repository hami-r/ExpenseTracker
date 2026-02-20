class Reimbursement {
  final int? reimbursementId;
  final int userId;
  final String sourceName;
  final String? category;
  final double amount;
  final DateTime? expectedDate;
  final double totalReimbursed;
  final String status;
  final String? notes;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reimbursement({
    this.reimbursementId,
    required this.userId,
    required this.sourceName,
    this.category,
    required this.amount,
    this.expectedDate,
    this.totalReimbursed = 0.0,
    this.status = 'active',
    this.notes,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reimbursement_id': reimbursementId,
      'user_id': userId,
      'source_name': sourceName,
      'category': category,
      'amount': amount,
      'expected_date': expectedDate?.toIso8601String().split('T')[0],
      'total_reimbursed': totalReimbursed,
      'status': status,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Reimbursement.fromMap(Map<String, dynamic> map) {
    return Reimbursement(
      reimbursementId: map['reimbursement_id'] as int?,
      userId: map['user_id'] as int,
      sourceName: map['source_name'] as String,
      category: map['category'] as String?,
      amount: (map['amount'] as num).toDouble(),
      expectedDate: map['expected_date'] != null
          ? DateTime.parse(map['expected_date'] as String)
          : null,
      totalReimbursed: map['total_reimbursed'] as double? ?? 0.0,
      status: map['status'] as String? ?? 'active',
      notes: map['notes'] as String?,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
