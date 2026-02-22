import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

enum ExportFormat { csv, excel }

enum SortOption { dateDesc, dateAsc, amountHighLow, amountLowHigh }

class DataManagementService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create a backup of the SQLite database
  Future<void> createBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'expense_tracker.db');
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Database file not found');
      }

      // Create a specific name with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final backupName = 'expense_tracker_backup_$timestamp.db';

      final tempDir = await getTemporaryDirectory();
      final backupPath = join(tempDir.path, backupName);

      // Copy to temp dir to rename and share
      await sourceFile.copy(backupPath);

      await Share.shareXFiles([
        XFile(backupPath),
      ], text: 'Expense Tracker Backup ($timestamp)');
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  // Restore database from a file
  Future<void> restoreBackup() async {
    try {
      // Pick a file
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final importedFile = File(result.files.single.path!);

      final dbPath = await getDatabasesPath();
      final targetPath = join(dbPath, 'expense_tracker.db');

      // Close existing DB connection
      final db = await _dbHelper.database;
      if (db.isOpen) {
        await db.close();
      }

      // Replace file
      await importedFile.copy(targetPath);

      // Re-open DB to ensure it works
      await _dbHelper.database;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  // Save backup to device storage
  Future<void> saveBackupToDevice() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = join(dbPath, 'expense_tracker.db');
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Database file not found');
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'expense_tracker_backup_$timestamp.db';

      // Read file bytes
      final bytes = await sourceFile.readAsBytes();

      // Use FilePicker to save file
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Error saving backup: $e');
      rethrow;
    }
  }

  // Generate and export report
  // Generate and export report (returns file path)
  Future<String> exportReport({
    required ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeItemizedDetails = true,
    bool includePaymentMethod = true,
    bool includeNotes = false,
    SortOption sortOption = SortOption.dateDesc,
    List<int>? selectedCategoryIds,
    bool includeSummary = false,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Build Query
      String query =
          '''
        SELECT 
          t.transaction_date,
          c.name as category,
          t.amount,
          pm.name as payment_method,
          t.note
          ${includeItemizedDetails ? ', si.name as split_item_name, si.amount as split_amount' : ''}
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.category_id
        LEFT JOIN payment_methods pm ON t.payment_method_id = pm.payment_method_id
        ${includeItemizedDetails ? 'LEFT JOIN split_items si ON t.transaction_id = si.transaction_id' : ''}
        WHERE 1=1
      ''';

      List<dynamic> args = [];
      if (startDate != null && endDate != null) {
        query += ' AND date(t.transaction_date) BETWEEN ? AND ?';
        args.add(startDate.toIso8601String().split('T')[0]);
        args.add(endDate.toIso8601String().split('T')[0]);
      }

      if (selectedCategoryIds != null && selectedCategoryIds.isNotEmpty) {
        query += ' AND t.category_id IN (${selectedCategoryIds.join(',')})';
      }

      switch (sortOption) {
        case SortOption.dateDesc:
          query += ' ORDER BY t.transaction_date DESC';
          break;
        case SortOption.dateAsc:
          query += ' ORDER BY t.transaction_date ASC';
          break;
        case SortOption.amountHighLow:
          query += ' ORDER BY t.amount DESC';
          break;
        case SortOption.amountLowHigh:
          query += ' ORDER BY t.amount ASC';
          break;
      }

      final List<Map<String, dynamic>> results = await db.rawQuery(query, args);

      if (format == ExportFormat.csv) {
        return await _exportCsv(
          results,
          includePaymentMethod,
          includeNotes,
          includeItemizedDetails,
        );
      } else {
        return await _exportExcel(
          results,
          includePaymentMethod,
          includeNotes,
          includeItemizedDetails,
          includeSummary,
        );
      }
    } catch (e) {
      debugPrint('Error exporting report: $e');
      rethrow;
    }
  }

  Future<String> _exportCsv(
    List<Map<String, dynamic>> results,
    bool includePaymentMethod,
    bool includeNotes,
    bool includeItemizedDetails,
  ) async {
    final StringBuffer csvBuffer = StringBuffer();

    // Header
    List<String> headers = ['Date', 'Category', 'Amount'];
    if (includeItemizedDetails) headers.addAll(['Item Name', 'Item Amount']);
    if (includePaymentMethod) headers.add('Payment Method');
    if (includeNotes) headers.add('Note');

    csvBuffer.writeln(headers.join(','));

    // Rows
    for (var row in results) {
      final date = row['transaction_date'] ?? '';
      final category = row['category'] ?? 'Uncategorized';
      final amount = row['amount'] ?? 0;

      List<String> rowData = ['$date', '$category', '$amount'];

      if (includeItemizedDetails) {
        rowData.add(row['split_item_name'] ?? '');
        rowData.add('${row['split_amount'] ?? ''}');
      }

      if (includePaymentMethod) {
        rowData.add(row['payment_method'] ?? 'Unknown');
      }

      if (includeNotes) {
        rowData.add(
          (row['note'] as String? ?? '')
              .replaceAll(',', ' ')
              .replaceAll('\n', ' '),
        );
      }

      csvBuffer.writeln(rowData.join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filePath = join(tempDir.path, 'expense_report_$timestamp.csv');

    final file = File(filePath);
    await file.writeAsString(csvBuffer.toString());

    return filePath;
  }

  Future<String> _exportExcel(
    List<Map<String, dynamic>> results,
    bool includePaymentMethod,
    bool includeNotes,
    bool includeItemizedDetails,
    bool includeSummary,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Header
    List<String> headers = ['Date', 'Category', 'Amount'];
    if (includeItemizedDetails) headers.addAll(['Item Name', 'Item Amount']);
    if (includePaymentMethod) headers.add('Payment Method');
    if (includeNotes) headers.add('Note');

    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    // Rows
    for (var row in results) {
      final date = row['transaction_date'] ?? '';
      final category = row['category'] ?? 'Uncategorized';
      final amount = row['amount'] ?? 0;

      List<CellValue> rowData = [
        TextCellValue('$date'),
        TextCellValue('$category'),
        DoubleCellValue(double.tryParse('$amount') ?? 0.0),
      ];

      if (includeItemizedDetails) {
        rowData.add(TextCellValue(row['split_item_name'] ?? ''));
        rowData.add(
          DoubleCellValue(
            double.tryParse('${row['split_amount'] ?? 0}') ?? 0.0,
          ),
        );
      }

      if (includePaymentMethod) {
        rowData.add(TextCellValue(row['payment_method'] ?? 'Unknown'));
      }

      if (includeNotes) {
        rowData.add(TextCellValue(row['note'] ?? ''));
      }

      sheetObject.appendRow(rowData);
    }

    // Summary Sheet
    if (includeSummary) {
      final summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('Category'),
        TextCellValue('Total Amount'),
      ]);

      final Map<String, double> categoryTotals = {};
      for (var row in results) {
        final category = row['category'] as String? ?? 'Uncategorized';
        final amount = double.tryParse(row['amount'].toString()) ?? 0.0;
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }

      // Sort summary by amount descending
      final sortedEntries = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (var entry in sortedEntries) {
        summarySheet.appendRow([
          TextCellValue(entry.key),
          DoubleCellValue(entry.value),
        ]);
      }
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filePath = join(tempDir.path, 'expense_report_$timestamp.xlsx');

    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      return filePath;
    }
    throw Exception('Failed to save Excel file');
  }

  Future<void> saveFileToDevice(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final fileName = basename(filePath);
      final bytes = await file.readAsBytes();

      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Error saving file to device: $e');
      rethrow;
    }
  }
}
