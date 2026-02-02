import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/transaction_service.dart';
import '../database/services/user_service.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../models/transaction.dart' as model;

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final List<String> _logs = [];
  bool _isLoading = false;

  // Services
  final _userService = UserService();
  final _categoryService = CategoryService();
  final _paymentMethodService = PaymentMethodService();
  final _transactionService = TransactionService();
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _runHealthCheck();
  }

  void _addLog(String message, {bool isError = false, bool isSuccess = false}) {
    setState(() {
      String prefix = isError ? '❌ ' : (isSuccess ? '✅ ' : 'ℹ️ ');
      _logs.add(
        '$prefix${DateTime.now().toString().split('.').first}: $message',
      );
    });
  }

  Future<void> _runHealthCheck() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });
    _addLog('Starting Database Health Check...');

    try {
      final db = await _dbHelper.database;
      _addLog('Database connection established', isSuccess: true);

      final tables = [
        'users',
        'categories',
        'payment_methods',
        'transactions',
        'loans',
        'receivables',
        'ious',
        'reimbursements',
      ];

      for (var table in tables) {
        final count = await db.query(table);
        _addLog('Table [$table]: ${count.length} rows', isSuccess: true);
      }

      final user = await _userService.getCurrentUser();
      if (user != null) {
        _addLog('Current User: ${user.name} (${user.email})', isSuccess: true);
      } else {
        _addLog('No current user found!', isError: true);
      }
    } catch (e) {
      _addLog('Health Check Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runCategoryTests() async {
    setState(() => _isLoading = true);
    _addLog('--- RUNNING CATEGORY TESTS ---');
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) throw Exception('No user');

      // Create
      final newCategory = Category(
        userId: user.userId!,
        name: 'Test Category ${DateTime.now().second}',
        iconName: 'food',
        colorHex: '#FF5733',
        // type: 'expense', // Not in model yet
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      int id = await _categoryService.createCategory(newCategory);
      _addLog('Created category with ID: $id', isSuccess: true);

      // Read
      final loaded = await _categoryService.getCategoryById(id);
      if (loaded != null && loaded.name == newCategory.name) {
        _addLog('Verified category creation', isSuccess: true);
      } else {
        _addLog('Failed verification', isError: true);
      }

      // Update
      final updated = loaded!.copyWith(name: 'Updated Test Name');
      await _categoryService.updateCategory(updated);
      final reloaded = await _categoryService.getCategoryById(id);
      if (reloaded?.name == 'Updated Test Name') {
        _addLog('Verified update', isSuccess: true);
      }

      // Soft Delete
      await _categoryService.deactivateCategory(id);
      final all = await _categoryService.getAllCategories(user.userId!);
      if (!all.any((c) => c.categoryId == id)) {
        _addLog(
          'Verified soft delete (removed from active list)',
          isSuccess: true,
        );
      }
    } catch (e) {
      _addLog('Category Tests Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runTransactionTests() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _addLog('--- RUNNING TRANSACTION TESTS ---');

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) return;

      // Get dependencies
      final cats = await _categoryService.getAllCategories(user.userId!);
      final methods = await _paymentMethodService.getAllPaymentMethods(
        user.userId!,
      );

      if (cats.isEmpty || methods.isEmpty) {
        _addLog(
          'Cannot run test: No categories or payment methods',
          isError: true,
        );
        return;
      }

      // Create
      final tx = model.Transaction(
        userId: user.userId!,
        categoryId: cats.first.categoryId!,
        paymentMethodId: methods.first.paymentMethodId!,
        amount: 500.0,
        transactionDate: DateTime.now(),
        note: 'Test Transaction',
        createdAt: DateTime.now(),
      );

      final id = await _transactionService.createTransaction(tx);
      _addLog('Created transaction ID: $id', isSuccess: true);

      // Verify Details
      final loaded = await _transactionService.getTransactionById(id);
      if (loaded != null && loaded.amount == 500.0) {
        _addLog('Verified transaction creation', isSuccess: true);
      }

      // Update
      final updated = loaded!.copyWith(amount: 750.0);
      await _transactionService.updateTransaction(updated);
      final reloaded = await _transactionService.getTransactionById(id);
      if (reloaded?.amount == 750.0) {
        _addLog('Verified transaction update', isSuccess: true);
      }

      // Delete
      await _transactionService.deleteTransaction(id);
      final finalCheck = await _transactionService.getTransactionById(id);
      if (finalCheck == null) {
        _addLog('Verified transaction deletion', isSuccess: true);
      }
    } catch (e) {
      _addLog('Transaction Tests Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Table Inspector Logic
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];

  Future<void> _loadTableData(String tableName) async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final data = await db.query(tableName);
      setState(() {
        _selectedTable = tableName;
        _tableData = data;
      });
    } catch (e) {
      _addLog('Error loading table $tableName: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTablesTab(bool isDark) {
    if (_selectedTable == null) {
      final tables = [
        'users',
        'categories',
        'payment_methods',
        'transactions',
        'loans',
        'receivables',
        'ious',
        'reimbursements',
      ];
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          return Card(
            child: ListTile(
              title: Text(table),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _loadTableData(table),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedTable = null;
                    _tableData = [];
                  });
                },
              ),
              Text(
                _selectedTable!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadTableData(_selectedTable!),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tableData.isEmpty
              ? const Center(child: Text('No data in this table'))
              : Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                          ),
                          headingRowColor: MaterialStateProperty.all(
                            isDark ? Colors.grey[900] : Colors.grey[100],
                          ),
                          columns: _tableData.first.keys
                              .map((key) => DataColumn(label: Text(key)))
                              .toList(),
                          rows: _tableData.map((row) {
                            return DataRow(
                              cells: row.values.map((value) {
                                return DataCell(
                                  Text(
                                    value?.toString() ?? 'null',
                                    style: TextStyle(
                                      color: value == null ? Colors.grey : null,
                                      fontStyle: value == null
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _runPaymentMethodTests() async {
    setState(() => _isLoading = true);
    _addLog('--- RUNNING PAYMENT METHOD TESTS ---');
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) throw Exception('No user');

      // Create
      final newMethod = PaymentMethod(
        userId: user.userId!,
        name: 'Test Method ${DateTime.now().second}',
        type: 'Card',
        iconName: 'card',
        colorHex: '#336699',
        isActive: true,
        displayOrder: 99,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      int id = await _paymentMethodService.createPaymentMethod(newMethod);
      _addLog('Created payment method with ID: $id', isSuccess: true);

      // Read
      final loaded = await _paymentMethodService.getPaymentMethodById(id);
      if (loaded != null && loaded.name == newMethod.name) {
        _addLog('Verified creation', isSuccess: true);
      } else {
        _addLog('Failed verification', isError: true);
      }

      // Update
      final updated = PaymentMethod(
        paymentMethodId: id,
        userId: user.userId!,
        name: 'Updated Method Name',
        type: 'Card',
        iconName: 'card',
        colorHex: '#336699',
        isActive: true,
        displayOrder: 99,
        createdAt: loaded?.createdAt,
        updatedAt: DateTime.now(),
      );

      await _paymentMethodService.updatePaymentMethod(updated);
      final reloaded = await _paymentMethodService.getPaymentMethodById(id);
      if (reloaded?.name == 'Updated Method Name') {
        _addLog('Verified update', isSuccess: true);
      }

      // Soft Delete
      await _paymentMethodService.deactivatePaymentMethod(id);
      final all = await _paymentMethodService.getAllPaymentMethods(
        user.userId!,
      );
      if (!all.any((m) => m.paymentMethodId == id)) {
        _addLog(
          'Verified soft delete (removed from active list)',
          isSuccess: true,
        );
      }
    } catch (e) {
      _addLog('Payment Method Tests Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Tests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Console'),
            Tab(text: 'Tables'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Console Tab
          Column(
            children: [
              Expanded(
                child: Container(
                  color: isDark ? Colors.black : const Color(0xFFf1f5f9),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color color = isDark ? Colors.white : Colors.black;
                      if (log.startsWith('❌')) color = Colors.red;
                      if (log.startsWith('✅')) color = Colors.green;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _runHealthCheck,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Run Health Check'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _logs.join('\n')),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logs copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Logs',
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tables Tab
          _buildTablesTab(isDark),

          // Actions Tab
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildActionCard(
                'Category Tests',
                'Create, Update, Soft-Delete Category',
                Icons.category,
                _runCategoryTests,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                'Transaction Tests',
                'Create, Update, Delete Transaction',
                Icons.receipt_long,
                _runTransactionTests,
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                'Payment Method Tests',
                'Create, Update, Soft-Delete Payment Method',
                Icons.credit_card,
                _runPaymentMethodTests,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? const Text('Coming Soon')
            : const Icon(Icons.play_arrow),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }
}
