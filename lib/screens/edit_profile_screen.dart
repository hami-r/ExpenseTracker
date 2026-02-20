import 'package:flutter/material.dart';
import '../models/user.dart';
import '../database/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          // There's no title in User, using email or empty
          _titleController.text = user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null) return;

    // Save state back to user DB
    try {
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        email: _titleController.text.trim(), // Storing "title" in email for now
      );

      await _userService.updateUser(updatedUser);
      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate user data changed
      }
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0f172a),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Profile Image Area
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1e293b)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.39,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFf1f5f9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 64,
                                      color: isDark
                                          ? const Color(0xFF64748b)
                                          : const Color(0xFFcbd5e1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF131f17)
                                            : const Color(0xFFf6f8f7),
                                        width: 4,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Inputs
                          _buildInputField(
                            label: 'FULL NAME',
                            controller: _nameController,
                            icon: Icons.person_rounded,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            label: 'TITLE / PROFESSION',
                            controller: _titleController,
                            icon: Icons.badge_rounded,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: primaryColor.withValues(alpha: 0.5),
                          ).copyWith(
                            elevation: WidgetStateProperty.resolveWith<double>((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.pressed))
                                return 2;
                              return 8; // Default elevation for shadow
                            }),
                          ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF64748b) : const Color(0xFF9ca3af),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0f172a).withOpacity(0.5)
                  : const Color(0xFFf8fafc),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0f172a),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                suffixIcon: Icon(
                  icon,
                  color: isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFF9ca3af),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
