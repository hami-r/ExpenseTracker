class User {
  final int? userId;
  final String name;
  final String? email;
  final String? phone;
  final String? countryCode;
  final String? avatarPath;
  final String themePreference;
  final String themeColor;
  final int primaryCurrencyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.userId,
    required this.name,
    this.email,
    this.phone,
    this.countryCode,
    this.avatarPath,
    this.themePreference = 'system',
    this.themeColor = 'Emerald Green',
    this.primaryCurrencyId = 1,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'country_code': countryCode,
      'avatar_path': avatarPath,
      'theme_preference': themePreference,
      'theme_color': themeColor,
      'primary_currency_id': primaryCurrencyId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      countryCode: map['country_code'] as String?,
      avatarPath: map['avatar_path'] as String?,
      themePreference: map['theme_preference'] as String? ?? 'system',
      themeColor: map['theme_color'] as String? ?? 'Emerald Green',
      primaryCurrencyId: map['primary_currency_id'] as int? ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  User copyWith({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? countryCode,
    String? avatarPath,
    String? themePreference,
    String? themeColor,
    int? primaryCurrencyId,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      avatarPath: avatarPath ?? this.avatarPath,
      themePreference: themePreference ?? this.themePreference,
      themeColor: themeColor ?? this.themeColor,
      primaryCurrencyId: primaryCurrencyId ?? this.primaryCurrencyId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
