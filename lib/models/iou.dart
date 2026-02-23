class IOU {
  final int? iouId;
  final int userId;
  final String creditorName;
  final double amount;
  final double estimatedTotalPayable;
  final String? reason;
  final DateTime? dueDate;
  final double totalPaid;
  final String status;
  final String? notes;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IOU({
    this.iouId,
    required this.userId,
    required this.creditorName,
    required this.amount,
    this.estimatedTotalPayable = 0.0,
    this.reason,
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
      'iou_id': iouId,
      'user_id': userId,
      'creditor_name': creditorName,
      'amount': amount,
      'estimated_total_payable': estimatedTotalPayable,
      'reason': reason,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'total_paid': totalPaid,
      'status': status,
      'notes': notes,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory IOU.fromMap(Map<String, dynamic> map) {
    return IOU(
      iouId: map['iou_id'] as int?,
      userId: map['user_id'] as int,
      creditorName: map['creditor_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      estimatedTotalPayable:
          (map['estimated_total_payable'] as num?)?.toDouble() ??
          (map['amount'] as num).toDouble(),
      reason: map['reason'] as String?,
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
