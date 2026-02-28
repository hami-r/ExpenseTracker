class PaymentMethod {
  final int? paymentMethodId;
  final int userId;
  final String name;
  final String type;
  final String? iconName;
  final String? colorHex;
  final String? accountNumber;
  final String? cardSubtype;
  final DateTime? cardIssuedOn;
  final int? billGenerationDay;
  final bool isPrimary;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    this.paymentMethodId,
    required this.userId,
    required this.name,
    required this.type,
    this.iconName,
    this.colorHex,
    this.accountNumber,
    this.cardSubtype,
    this.cardIssuedOn,
    this.billGenerationDay,
    this.isPrimary = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'payment_method_id': paymentMethodId,
      'user_id': userId,
      'name': name,
      'type': type,
      'icon_name': iconName,
      'color_hex': colorHex,
      'account_number': accountNumber,
      'card_subtype': cardSubtype,
      'card_issued_on': cardIssuedOn?.toIso8601String().split('T')[0],
      'bill_generation_day': billGenerationDay,
      'is_primary': isPrimary ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      paymentMethodId: map['payment_method_id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      accountNumber: map['account_number'] as String?,
      cardSubtype: map['card_subtype'] as String?,
      cardIssuedOn: map['card_issued_on'] != null
          ? DateTime.parse(map['card_issued_on'] as String)
          : null,
      billGenerationDay: (map['bill_generation_day'] as num?)?.toInt(),
      isPrimary: (map['is_primary'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      displayOrder: map['display_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
