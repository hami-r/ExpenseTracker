enum TransactionType {
  expense,
  income, // For consistency, though mostly expense tracker
  loan,
  loanPayment,
  iou,
  iouPayment,
  receivable,
  receivablePayment,
  reimbursement,
  reimbursementPayment,
}

class TransactionItem {
  final int id;
  final int? userId;
  final double amount;
  final DateTime date;
  final String title;
  final String? subtitle;
  final TransactionType type;
  final String? status; // 'active', 'paid', 'pending', etc.
  final bool isSplit;
  final int? categoryId;
  final int? paymentMethodId;
  final String? paymentMethodName;
  final String? categoryName; // For expenses
  final String? colorHex; // For category color

  TransactionItem({
    required this.id,
    this.userId,
    required this.amount,
    required this.date,
    required this.title,
    this.subtitle,
    required this.type,
    this.status,
    this.isSplit = false,
    this.categoryId,
    this.paymentMethodId,
    this.paymentMethodName,
    this.categoryName,
    this.colorHex,
  });
}
