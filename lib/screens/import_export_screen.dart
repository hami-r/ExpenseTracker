import 'package:flutter/material.dart';
import '../database/services/data_management_service.dart';
import 'export_report_screen.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final DataManagementService _dataManagementService = DataManagementService();
  bool _isLoading = false;

  Future<void> _handleBackup() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.share_rounded,
                color: Color(0xFF10b981),
              ),
              title: const Text('Share Backup'),
              subtitle: const Text('Send via email, WhatsApp, etc.'),
              onTap: () {
                Navigator.pop(context);
                _performBackup(isShare: true);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.save_alt_rounded,
                color: Color(0xFF3b82f6),
              ),
              title: const Text('Save to Device'),
              subtitle: const Text('Save directly to your phone storage'),
              onTap: () {
                Navigator.pop(context);
                _performBackup(isShare: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performBackup({required bool isShare}) async {
    setState(() => _isLoading = true);
    try {
      if (isShare) {
        await _dataManagementService.createBackup();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup ready to share')),
          );
        }
      } else {
        await _dataManagementService.saveBackupToDevice();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    // Show warning dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning: Overwrite Data'),
        content: const Text(
          'Restoring a backup will completely overwrite your current data. This action cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _dataManagementService.restoreBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore successful. Please restart the app.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleExportReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExportReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF131f17).withOpacity(0.8)
            : const Color(0xFFf6f8f7).withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF475569),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Import & Export',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0f172a),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Manage your data securely. Create local backups or export reports for analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Backup Card
                  _buildActionCard(
                    context,
                    title: 'Backup Data',
                    subtitle: 'Download your local SQLite database',
                    icon: Icons.cloud_upload_rounded,
                    color: const Color(0xFF10b981), // Emerald
                    buttonText: 'Create Backup',
                    onTap: _handleBackup,
                    isDark: isDark,
                    gradientStart: const Color(0xFF10b981).withOpacity(0.1),
                    iconBg: const Color(0xFFecfdf5),
                    iconBgDark: const Color(0xFF064e3b),
                  ),
                  const SizedBox(height: 16),

                  // Restore Card
                  _buildActionCard(
                    context,
                    title: 'Restore Data',
                    subtitle: 'Upload a previously saved SQLite file',
                    icon: Icons.cloud_download_rounded,
                    color: const Color(0xFF3b82f6), // Blue
                    buttonText: 'Select File',
                    onTap: _handleRestore,
                    isDark: isDark,
                    gradientStart: const Color(0xFF3b82f6).withOpacity(0.1),
                    iconBg: const Color(0xFFeff6ff),
                    iconBgDark: const Color(0xFF1e3a8a),
                  ),
                  const SizedBox(height: 16),

                  // Export Report Card
                  _buildActionCard(
                    context,
                    title: 'Export Report',
                    subtitle: 'Download spending in CSV or XLSX format',
                    icon: Icons.description_rounded,
                    color: const Color(0xFFa855f7), // Purple
                    buttonText: 'Generate Report',
                    onTap: _handleExportReport,
                    isDark: isDark,
                    gradientStart: const Color(0xFFa855f7).withOpacity(0.1),
                    iconBg: const Color(0xFFfaf5ff),
                    iconBgDark: const Color(0xFF581c87),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Data privacy is our priority. All backups are stored locally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
    required bool isDark,
    required Color gradientStart,
    required Color iconBg,
    required Color iconBgDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, Colors.transparent],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(60),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? iconBgDark : iconBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 32, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF64748b),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
