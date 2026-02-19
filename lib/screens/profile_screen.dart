import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manage_categories_screen.dart';
import 'manage_payment_methods_screen.dart';
import 'database_test_screen.dart';
import 'liabilities_loans_screen.dart';
import 'money_owed_screen.dart';
import 'theme_selection_screen.dart';
import 'import_export_screen.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1e293b)
                              : const Color(0xFFf1f5f9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 24,
                          color: isDark
                              ? const Color(0xFFcbd5e1)
                              : const Color(0xFF64748b),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Card
                        _buildProfileCard(isDark),
                        const SizedBox(height: 32),

                        // Financial Assets Section
                        _buildSectionHeader('FINANCIAL ASSETS', isDark),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _MenuItemData(
                            icon: Icons.category_rounded,
                            title: 'Manage Categories',
                            color: const Color(0xFF3b82f6),
                            hasBottomBorder: true,
                          ),
                          _MenuItemData(
                            icon: Icons.credit_card_rounded,
                            title: 'Manage Payment Methods',
                            color: const Color(0xFFf59e0b),
                            hasBottomBorder: false,
                          ),
                        ], isDark),
                        const SizedBox(height: 32),

                        // Debt & Loans Section
                        _buildSectionHeader('DEBT & LOANS', isDark),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _MenuItemData(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Liabilities & Loans',
                            color: const Color(0xFFf59e0b),
                            hasBottomBorder: true,
                          ),
                          _MenuItemData(
                            icon: Icons.attach_money_rounded,
                            title: 'Money Owed to Me',
                            color: Theme.of(context).colorScheme.primary,
                            hasBottomBorder: false,
                          ),
                        ], isDark),
                        const SizedBox(height: 32),

                        // Analysis & Reports Section
                        _buildSectionHeader('ANALYSIS & REPORTS', isDark),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _MenuItemData(
                            icon: Icons.scatter_plot_rounded,
                            title: 'Payment Mode Correlation',
                            color: const Color(0xFF3b82f6),
                            hasBottomBorder: true,
                          ),
                          _MenuItemData(
                            icon: Icons.analytics_rounded,
                            title: 'Monthly Comparison',
                            color: Theme.of(context).colorScheme.primary,
                            hasBottomBorder: false,
                          ),
                        ], isDark),
                        const SizedBox(height: 32),

                        // General Section
                        _buildSectionHeader('GENERAL', isDark),
                        const SizedBox(height: 12),
                        _buildMenuCard([
                          _MenuItemData(
                            icon: Icons.import_export_rounded,
                            title: 'Import and Export',
                            color: const Color(0xFF64748b),
                            hasBottomBorder: true,
                          ),
                          _MenuItemData(
                            icon: Icons.bug_report_rounded,
                            title: 'Database Tests',
                            color: const Color(0xFFef4444),
                            hasBottomBorder: true,
                          ),
                          _MenuItemData(
                            icon: Icons.dark_mode_rounded,
                            title: 'Dark Mode',
                            color: const Color(0xFF64748b),
                            hasBottomBorder: true,
                            isToggle: true,
                          ),
                          _MenuItemData(
                            icon: Icons.palette_rounded,
                            title: 'Theme',
                            color: Theme.of(context).colorScheme.primary,
                            hasBottomBorder: false,
                          ),
                        ], isDark),
                        const SizedBox(height: 24),

                        // Version
                        Center(
                          child: Text(
                            'Version 2.4.0',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF9ca3af),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1e293b)
                        : const Color(0xFFf1f5f9),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        Icons.dashboard_rounded,
                        'Dashboard',
                        0,
                        isDark,
                      ),
                      _buildNavItem(
                        Icons.receipt_long_rounded,
                        'Transactions',
                        1,
                        isDark,
                      ),
                      _buildNavItem(
                        Icons.account_balance_wallet_rounded,
                        'Budget',
                        2,
                        isDark,
                      ),
                      _buildNavItem(Icons.person_rounded, 'Profile', 3, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient decoration
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(128),
                ),
              ),
            ),
          ),
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF475569), const Color(0xFF1e293b)]
                            : [
                                const Color(0xFFf1f5f9),
                                const Color(0xFFe2e8f0),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: isDark
                          ? const Color(0xFF34d399)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Name and title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PERSONAL ACCOUNTANT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: isDark
                            ? const Color(0xFF34d399)
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1e293b)
                      : const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF9ca3af),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: isDark ? const Color(0xFF64748b) : const Color(0xFF9ca3af),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItemData> items, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          return _buildMenuItem(item, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.isToggle
            ? null
            : () {
                if (item.title == 'Manage Categories') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesScreen(),
                    ),
                  );
                } else if (item.title == 'Manage Payment Methods') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManagePaymentMethodsScreen(),
                    ),
                  );
                } else if (item.title == 'Liabilities & Loans') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiabilitiesLoansScreen(),
                    ),
                  );
                } else if (item.title == 'Money Owed to Me') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MoneyOwedScreen(),
                    ),
                  );
                } else if (item.title == 'Theme') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelectionScreen(),
                    ),
                  );
                } else if (item.title == 'Database Tests') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatabaseTestScreen(),
                    ),
                  );
                } else if (item.title == 'Import and Export') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportExportScreen(),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: item.hasBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF1e293b).withOpacity(0.5)
                          : const Color(0xFFf1f5f9),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFe2e8f0)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
              if (item.isToggle)
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    );
                  },
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF4b5563)
                      : const Color(0xFFd1d5db),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = index == 3; // Profile is always selected on this screen
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        if (index == 0) {
          // Navigate back to home when Dashboard is tapped
          Navigator.pop(context);
        }
        // Other navigation items can be implemented later
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? primaryColor
                  : isDark
                  ? const Color(0xFF64748b)
                  : const Color(0xFF94a3b8),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.5,
                color: isSelected
                    ? primaryColor
                    : isDark
                    ? const Color(0xFF64748b)
                    : const Color(0xFF94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final Color color;
  final bool hasBottomBorder;
  final bool isToggle;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.color,
    this.hasBottomBorder = false,
    this.isToggle = false,
  });
}
