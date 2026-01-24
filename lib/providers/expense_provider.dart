import 'package:flutter/foundation.dart' hide Category;
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [
    Expense(
      id: 'e1',
      title: 'Groceries',
      amount: 45.99,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: Category.groceries,
    ),
    Expense(
      id: 'e2',
      title: 'Netflix Subscription',
      amount: 15.99,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: Category.entertainment,
    ),
    Expense(
      id: 'e3',
      title: 'Gym Membership',
      amount: 40.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: Category.health,
    ),
    Expense(
      id: 'e4',
      title: 'Uber Ride',
      amount: 25.50,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      category: Category.transport,
    ),
    Expense(
      id: 'e5',
      title: 'Dinner at Steakhouse',
      amount: 120.00,
      date: DateTime.now(),
      category: Category.food,
    ),
  ];

  List<Expense> get expenses => [..._expenses];

  double get totalBalance {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  void removeExpense(String id) {
    _expenses.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
