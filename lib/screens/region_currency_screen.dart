import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/services/profile_service.dart';
import '../database/services/user_service.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import 'edit_region_profile_screen.dart';

class RegionCurrencyScreen extends StatefulWidget {
  const RegionCurrencyScreen({super.key});

  @override
  State<RegionCurrencyScreen> createState() => _RegionCurrencyScreenState();
}

class _RegionCurrencyScreenState extends State<RegionCurrencyScreen> {
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  List<Profile> _profiles = [];
  int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final user = await _userService.getCurrentUser();
    if (user == null || !mounted) return;
    _userId = user.userId;
    final profiles = await _profileService.getAllProfiles(user.userId!);
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchProfile(Profile profile) async {
    if (profile.isActive) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Switch Region'),
        content: Text(
          'Are you sure you want to switch to "${profile.name}"? This will change your active currency and financial data view.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _profileService.setActiveProfile(profile.profileId!, _userId!);
    if (!mounted) return;
    await context.read<ProfileProvider>().switchProfile(profile, _userId!);
    await _loadProfiles();
  }

  Future<void> _deleteProfile(Profile profile) async {
    if (profile.isActive) {
      _showSnack('Cannot delete the active profile.');
      return;
    }
    if (_profiles.length == 1) {
      _showSnack('You must have at least one profile.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Profile'),
        content: Text(
          'Delete "${profile.name}"? All transactions, budgets, and loans in this profile will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _profileService.deleteProfile(profile.profileId!);
      await _loadProfiles();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openEdit(Profile? profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditRegionProfileScreen(userId: _userId!, existing: profile),
      ),
    );
    await _loadProfiles();
    if (mounted) {
      await context.read<ProfileProvider>().refresh(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final active = _profiles.where((p) => p.isActive).firstOrNull;
    final others = _profiles.where((p) => !p.isActive).toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Region & Currency',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0f172a),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Active Profile
                              _sectionLabel('Active Profile'),
                              const SizedBox(height: 12),
                              if (active != null)
                                _buildActiveCard(active, isDark, primaryColor),

                              const SizedBox(height: 28),

                              // Other Profiles
                              if (others.isNotEmpty) ...[
                                _sectionLabel('Available Profiles'),
                                const SizedBox(height: 12),
                                ...others.map(
                                  (p) =>
                                      _buildProfileRow(p, isDark, primaryColor),
                                ),
                              ],

                              const SizedBox(height: 16),
                              // Info note
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Switching profiles changes your currency and database context. Your data is isolated per region.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // FAB
            Positioned(
              bottom: 24,
              right: 20,
              child: GestureDetector(
                onTap: () => _openEdit(null),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Add Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildActiveCard(Profile p, bool isDark, Color primary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flag circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          p.flagEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _iconBtn(
                          Icons.edit_rounded,
                          isDark ? Colors.grey[700]! : Colors.grey[100]!,
                          isDark ? Colors.grey[300]! : Colors.grey[600]!,
                          () => _openEdit(p),
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          Icons.delete_rounded,
                          Colors.red.withValues(alpha: 0.1),
                          Colors.red,
                          () => _deleteProfile(p),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.currencySymbol} ${p.currencyName} (${p.currencyCode})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(Profile p, bool isDark, Color primary) {
    return GestureDetector(
      onTap: () => _switchProfile(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(p.flagEmoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  Text(
                    '${p.currencySymbol} ${p.currencyCode}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            _iconBtn(
              Icons.edit_rounded,
              Colors.transparent,
              isDark ? Colors.grey[500]! : Colors.grey[400]!,
              () => _openEdit(p),
            ),
            const SizedBox(width: 4),
            _iconBtn(
              Icons.delete_rounded,
              Colors.transparent,
              isDark ? Colors.grey[500]! : Colors.grey[400]!,
              () => _deleteProfile(p),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.radio_button_unchecked_rounded,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
