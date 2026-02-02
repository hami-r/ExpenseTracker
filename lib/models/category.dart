class Category {
  final int? categoryId;
  final int userId;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final bool isSystem;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.categoryId,
    required this.userId,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.isSystem = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'user_id': userId,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_system': isSystem ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['category_id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      isSystem: (map['is_system'] as int?) == 1,
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

  Category copyWith({
    int? categoryId,
    int? userId,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    bool? isSystem,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
