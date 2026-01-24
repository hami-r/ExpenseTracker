import 'package:flutter/material.dart';

enum Category {
  food,
  transport,
  entertainment,
  shopping,
  health,
  groceries,
  shopping_bag, // duplicated for variety or use specific icons
  other,
}

extension CategoryExtension on Category {
  String get name {
    switch (this) {
      case Category.food: return 'Food';
      case Category.transport: return 'Transport';
      case Category.entertainment: return 'Entertainment';
      case Category.shopping: return 'Shopping';
      case Category.health: return 'Health';
      case Category.groceries: return 'Groceries';
      case Category.shopping_bag: return 'Style';
      case Category.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case Category.food: return Icons.restaurant;
      case Category.transport: return Icons.directions_car;
      case Category.entertainment: return Icons.movie;
      case Category.shopping: return Icons.shopping_cart;
      case Category.health: return Icons.medical_services;
      case Category.groceries: return Icons.local_grocery_store;
      case Category.shopping_bag: return Icons.shopping_bag;
      case Category.other: return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case Category.food: return const Color(0xFFFF9F43);
      case Category.transport: return const Color(0xFF54A0FF);
      case Category.entertainment: return const Color(0xFF5F27CD);
      case Category.shopping: return const Color(0xFFFF6B6B);
      case Category.health: return const Color(0xFF1DD1A1);
      case Category.groceries: return const Color(0xFFFeca57);
      case Category.shopping_bag: return const Color(0xFF48dbfb);
      case Category.other: return const Color(0xFFC8d6e5);
    }
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}
