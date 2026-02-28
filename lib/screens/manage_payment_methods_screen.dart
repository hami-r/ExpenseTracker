import 'package:flutter/material.dart';
import 'edit_payment_method_screen.dart';
import '../models/payment_method.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../utils/icon_helper.dart';
import '../utils/color_helper.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/delete_confirmation_dialog.dart';

class ManagePaymentMethodsScreen extends StatefulWidget {
  const ManagePaymentMethodsScreen({super.key});

  @override
  State<ManagePaymentMethodsScreen> createState() =>
      _ManagePaymentMethodsScreenState();
}

class _ManagePaymentMethodsScreenState
    extends State<ManagePaymentMethodsScreen> {
  List<PaymentMethod> paymentMethods = [];
  bool _isLoading = true;
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _userService.getCurrentUser();
    if (user != null) {
      if (!mounted) return;
      final profileId = context.read<ProfileProvider>().activeProfileId;
      final loadedMethods = await _paymentMethodService.getAllPaymentMethods(
        user.userId!,
        profileId: profileId,
      );
      if (mounted) {
        setState(() {
          paymentMethods = loadedMethods;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deletePaymentMethod(int index, BuildContext context) async {
    final method = paymentMethods[index];
    final methodName = method.name;

    // if (method.isPrimary) { ... } // Model logic for primary not yet fully integrated, skipping check or implementing if field exists (it doesn't in model, checking implicit rules if any)

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete Payment Method',
      message: 'Are you sure you want to delete "$methodName"?',
    );

    if (confirmed && method.paymentMethodId != null) {
      await _paymentMethodService.deactivatePaymentMethod(
        method.paymentMethodId!,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark
                          ? const Color(0xFFe5e7eb)
                          : const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Add New Method Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EditPaymentMethodScreen(),
                            ),
                          );
                          _loadData(); // Refresh on return
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Add New Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR METHODS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: isDark
                                ? const Color(0xFF64748b)
                                : const Color(0xFF66857d),
                          ),
                        ),
                        Text(
                          '${paymentMethods.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94a3b8)
                                : const Color(0xFF64748b),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Payment Methods List
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (paymentMethods.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No payment methods found',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94a3b8)
                                  : const Color(0xFF64748b),
                            ),
                          ),
                        ),
                      )
                    else
                      ...paymentMethods.asMap().entries.map((entry) {
                        return _buildPaymentCard(
                          entry.value,
                          entry.key,
                          isDark,
                        );
                      }),

                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentMethod method, int index, bool isDark) {
    // Model doesn't have isPrimary yet, assuming false or logic needed
    final isPrimary = false;
    final color = ColorHelper.fromHex(method.colorHex);
    final icon = IconHelper.getIcon(method.iconName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2c3035) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),

          const SizedBox(width: 16),

          // Name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (method.type == 'Card') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (method.cardSubtype ?? 'credit').toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF60a5fa)
                            : const Color(0xFF2563eb),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  method.accountNumber ?? method.type,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF66857d),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditPaymentMethodScreen(paymentMethod: method),
                    ),
                  );
                  _loadData();
                },
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF9ca3af),
                ),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFf3f4f6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              if (!isPrimary) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deletePaymentMethod(index, context),
                  icon: const Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: Color(0xFFef4444),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFef4444,
                    ).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
