class Currency {
  final int? currencyId;
  final String currencyCode;
  final String currencyName;
  final String symbol;
  final int decimalPlaces;
  final bool isActive;
  final DateTime? createdAt;

  Currency({
    this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.symbol,
    this.decimalPlaces = 2,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency_id': currencyId,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'symbol': symbol,
      'decimal_places': decimalPlaces,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      currencyId: map['currency_id'] as int?,
      currencyCode: map['currency_code'] as String,
      currencyName: map['currency_name'] as String,
      symbol: map['symbol'] as String,
      decimalPlaces: map['decimal_places'] as int? ?? 2,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
