class Receivable {
  final int? receivableId;
  final int userId;
  final String recipientName;
  final String receivableType;
  final double principalAmount;
  final double interestRate;
  final DateTime? expectedDate;
  final double totalReceived;
  final String status;
  final String? notes;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Receivable({
    this.receivableId,
    required this.userId,
    required this.recipientName,
    required this.receivableType,
    required this.principalAmount,
    this.interestRate = 0.0,
    this.expectedDate,
    this.totalReceived = 0.0,
    this.status = 'active',
    this.notes,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'receivable_id': receivableId,
      'user_id': userId,
      'recipient_name': recipientName,
      'receivable_type': receivableType,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'expected_date': expectedDate?.toIso8601String().split('T')[0],
      'total_received': totalReceived,
      'status': status,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Receivable.fromMap(Map<String, dynamic> map) {
    return Receivable(
      receivableId: map['receivable_id'] as int?,
      userId: map['user_id'] as int,
      recipientName: map['recipient_name'] as String,
      receivableType: map['receivable_type'] as String,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
      expectedDate: map['expected_date'] != null
          ? DateTime.parse(map['expected_date'] as String)
          : null,
      totalReceived: map['total_received'] as double? ?? 0.0,
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
