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
  final double amount;
  final DateTime date;
  final String title;
  final String? subtitle;
  final TransactionType type;
  final String? status; // 'active', 'paid', 'pending', etc.
  final bool isSplit;
  final String? categoryName; // For expenses
  final String? colorHex; // For category color

  TransactionItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.title,
    this.subtitle,
    required this.type,
    this.status,
    this.isSplit = false,
    this.categoryName,
    this.colorHex,
  });
}
