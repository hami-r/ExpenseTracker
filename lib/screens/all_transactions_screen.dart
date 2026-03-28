import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction_item.dart';
import '../database/services/all_transactions_service.dart';
import '../utils/color_helper.dart';
import '../utils/icon_helper.dart';
import '../providers/profile_provider.dart';
import 'transaction_details_screen.dart';
import 'loan_detail_screen.dart';
import 'iou_detail_screen.dart';
import 'receivable_detail_screen.dart';
import 'reimbursement_detail_screen.dart';
import 'split_expense_detail_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  final int refreshTrigger;

  const AllTransactionsScreen({super.key, this.refreshTrigger = 0});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final AllTransactionsService _service = AllTransactionsService();
  final ScrollController _scrollController = ScrollController();

  final List<TransactionItem> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  TransactionSortOption _sortOption = TransactionSortOption.dateDesc;
  TransactionType? _selectedTypeFilter;

  // Filter options for UI
  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'value': null},
    {'label': 'Expense', 'value': TransactionType.expense},
    {'label': 'Loan', 'value': TransactionType.loan},
    {'label': 'IOU', 'value': TransactionType.iou},
    {'label': 'Lent', 'value': TransactionType.receivable},
    // {'label': 'Pending', 'value': null}, // Complex filter, let's keep simple for now
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  int? _lastProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = context.watch<ProfileProvider>().activeProfileId;
    if (_lastProfileId != null && _lastProfileId != profileId) {
      _loadTransactions(refresh: true);
    }
    _lastProfileId = profileId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllTransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _loadTransactions(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (refresh) {
      _offset = 0;
      _transactions.clear();
      _hasMore = true;
    }

    try {
      final newTransactions = await _service.getTransactions(
        limit: _limit,
        offset: _offset,
        sortOption: _sortOption,
        typeFilter: _selectedTypeFilter != null ? [_selectedTypeFilter!] : null,
        profileId: mounted
            ? context.read<ProfileProvider>().activeProfileId
            : null,
      );

      setState(() {
        _transactions.addAll(newTransactions);
        _offset += newTransactions.length;
        _hasMore = newTransactions.length == _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading transactions: $e');
    }
  }

  void _updateFilter(TransactionType? type) {
    if (_selectedTypeFilter == type) return;
    setState(() {
      _selectedTypeFilter = type;
    });
    _loadTransactions(refresh: true);
  }

  void _updateSort(TransactionSortOption option) {
    if (_sortOption == option) return;
    setState(() {
      _sortOption = option;
    });
    _loadTransactions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryDarkColor = Colors.teal[300] ?? primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      appBar: AppBar(
        title: Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF30353E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<TransactionSortOption>(
            icon: Icon(
              Icons.sort_rounded,
              color: isDark ? Colors.white : const Color(0xFF30353E),
            ),
            onSelected: _updateSort,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TransactionSortOption.dateDesc,
                child: Text('Date (Newest First)'),
              ),
              const PopupMenuItem(
                value: TransactionSortOption.dateAsc,
                child: Text('Date (Oldest First)'),
              ),
              const PopupMenuItem(
                value: TransactionSortOption.amountHighLow,
                child: Text('Amount (High to Low)'),
              ),
              const PopupMenuItem(
                value: TransactionSortOption.amountLowHigh,
                child: Text('Amount (Low to High)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: _filterOptions.map((option) {
                final isSelected = _selectedTypeFilter == option['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(option['label']),
                    onSelected: (bool selected) {
                      _updateFilter(selected ? option['value'] : null);
                    },
                    backgroundColor: isDark
                        ? const Color(0xFF1a2c2b)
                        : Colors.white,
                    selectedColor: primaryColor.withValues(alpha: 0.16),
                    checkmarkColor: primaryColor,
                    side: BorderSide(
                      color: isSelected
                          ? primaryColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey[200]!),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark ? primaryColor : primaryDarkColor)
                          : (isDark
                                ? Colors.grey[300]
                                : const Color(0xFF717782)),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: _transactions.isEmpty && !_isLoading
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final transaction = _transactions[index];
                      final bool showHeader =
                          index == 0 ||
                          !_isSameMonth(
                            _transactions[index - 1].date,
                            transaction.date,
                          );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            _buildMonthHeader(transaction.date, isDark),
                          _buildTransactionTile(transaction, isDark),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  Widget _buildMonthHeader(DateTime date, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: Text(
        DateFormat('MMMM yyyy').format(date),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : const Color(0xFF717782),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionItem item, bool isDark) {
    final bool isIncome = _isIncome(item);
    final Color amountColor = isIncome
        ? const Color(0xFF10B981) // Green for money in
        : (isDark
              ? Colors.white
              : const Color(0xFF111827)); // Normal for money out
    final subtitle = _displaySubtitle(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getIconBgColor(item, isDark),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIcon(item), color: _getIconColor(item), size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF30353E),
                ),
              ),
            ),
            if (item.isSplit) _buildSplitBadge(item, isDark),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF717782),
                ),
              ),
            Text(
              DateFormat('MMM d, h:mm a').format(item.date),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? "+" : "-"}${context.read<ProfileProvider>().currencySymbol}${item.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
            if (item.status != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.status!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(item.status!, isDark),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          if (item.type == TransactionType.expense ||
              item.type == TransactionType.income) {
            // Map to the structure expected by TransactionDetailsScreen
            final transactionMap = {
              'id': item.id,
              'userId': item.userId,
              'title': item.title,
              'date': item.date,
              'amount': item.amount,
              'categoryId': item.categoryId,
              'paymentMethodId': item.paymentMethodId,
              'category': item.categoryName ?? 'Uncategorized',
              'icon': _getIcon(item),
              'color': _getIconColor(item),
              'note': item.note ?? '',
              'paymentMethod': item.paymentMethodName ?? 'Unknown',
            };

            if (item.isSplit) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SplitExpenseDetailScreen(transaction: transactionMap),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailsScreen(transaction: transactionMap),
                ),
              );
            }
          } else if (item.type == TransactionType.loan ||
              item.type == TransactionType.loanPayment) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanDetailScreen(loanId: item.id),
              ),
            );
          } else if (item.type == TransactionType.iou ||
              item.type == TransactionType.iouPayment) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IOUDetailScreen(iouId: item.id),
              ),
            );
          } else if (item.type == TransactionType.receivable ||
              item.type == TransactionType.receivablePayment) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReceivableDetailScreen(receivableId: item.id),
              ),
            );
          } else if (item.type == TransactionType.reimbursement ||
              item.type == TransactionType.reimbursementPayment) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReimbursementDetailScreen(reimbursementId: item.id),
              ),
            );
          }
        },
      ),
    );
  }

  bool _isIncome(TransactionItem item) {
    return item.type == TransactionType.income ||
        item.type == TransactionType.loan || // Getting a loan is money IN
        item.type == TransactionType.receivablePayment ||
        item.type == TransactionType.reimbursementPayment;
  }

  String? _displaySubtitle(TransactionItem item) {
    final rawSubtitle = item.subtitle?.trim();
    if (rawSubtitle == null || rawSubtitle.isEmpty) {
      return null;
    }

    final normalizedTitle = item.title.trim().toLowerCase();
    if (rawSubtitle.toLowerCase() == normalizedTitle) {
      return null;
    }

    return rawSubtitle;
  }

  Widget _buildSplitBadge(TransactionItem item, bool isDark) {
    final label = item.splitItemCount > 0
        ? 'Split ${item.splitItemCount}'
        : 'Split';

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  IconData _getIcon(TransactionItem item) {
    if (item.type == TransactionType.expense) {
      return IconHelper.getIcon('category_rounded');
    }
    if (item.type == TransactionType.loan) {
      return Icons.account_balance_wallet_rounded;
    }
    if (item.type == TransactionType.loanPayment) return Icons.payment_rounded;
    if (item.type == TransactionType.iou) return Icons.handshake_rounded;
    if (item.type == TransactionType.receivable) return Icons.upcoming_rounded;
    return Icons.receipt_long_rounded;
  }

  Color _getIconColor(TransactionItem item) {
    if (item.colorHex != null) return ColorHelper.fromHex(item.colorHex);
    return Theme.of(context).colorScheme.primary;
  }

  Color _getIconBgColor(TransactionItem item, bool isDark) {
    final color = _getIconColor(item);
    return color.withValues(alpha: 0.1);
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'active':
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}
