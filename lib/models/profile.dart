class Profile {
  final int? profileId;
  final int userId;
  final String name;
  final int currencyId;
  final String? countryCode;
  bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined from currencies table
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;

  Profile({
    this.profileId,
    required this.userId,
    required this.name,
    required this.currencyId,
    this.countryCode,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.currencyName = 'Indian Rupee',
  });

  Map<String, dynamic> toMap() {
    return {
      if (profileId != null) 'profile_id': profileId,
      'user_id': userId,
      'name': name,
      'currency_id': currencyId,
      'country_code': countryCode,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      profileId: map['profile_id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      currencyId: map['currency_id'] as int,
      countryCode: map['country_code'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
      currencyCode: map['currency_code'] as String? ?? 'INR',
      currencySymbol: map['symbol'] as String? ?? '₹',
      currencyName: map['currency_name'] as String? ?? 'Indian Rupee',
    );
  }

  Profile copyWith({
    int? profileId,
    int? userId,
    String? name,
    int? currencyId,
    String? countryCode,
    bool? isActive,
    String? currencyCode,
    String? currencySymbol,
    String? currencyName,
  }) {
    return Profile(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      currencyId: currencyId ?? this.currencyId,
      countryCode: countryCode ?? this.countryCode,
      isActive: isActive ?? this.isActive,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyName: currencyName ?? this.currencyName,
    );
  }

  /// Country code to flag emoji
  String get flagEmoji {
    final code = countryCode?.toUpperCase() ?? '';
    if (code.length != 2) return '🌍';
    return String.fromCharCodes(code.codeUnits.map((c) => c - 0x41 + 0x1F1E6));
  }
}
