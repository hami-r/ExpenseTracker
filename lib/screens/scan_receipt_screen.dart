import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../database/services/ai_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'add_expense_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _userService = UserService();
  late final AIService _aiService;
  bool _isProcessing = false;

  // Picked image state
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _aiService = AIService(CategoryService(), PaymentMethodService());
  }

  // Step 1: Pick an image and show preview — does NOT call Gemini
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    if (!mounted) return;
    setState(() {
      _pickedImageFile = File(pickedFile.path);
      _pickedImageBytes = bytes;
    });
  }

  // Step 2: Send image to Gemini when user confirms
  Future<void> _processImage() async {
    if (_pickedImageBytes == null) return;

    final user = await _userService.getCurrentUser();
    if (user == null || user.userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (!mounted) return;
      final profileId = context.read<ProfileProvider>().activeProfileId;
      final parsedData = await _aiService.parseImageToExpense(
        _pickedImageBytes!,
        user.userId!,
        profileId: profileId,
      );
      if (!mounted) return;

      if (parsedData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(
              initialAmount: (parsedData['amount'] as num?)?.toDouble(),
              initialCategoryId: parsedData['category_id'] as int?,
              initialPaymentMethodId: parsedData['payment_method_id'] as int?,
              initialNote: parsedData['note'] as String?,
              initialDate: parsedData['date'] != null
                  ? DateTime.tryParse(parsedData['date'] as String)
                  : null,
              initialIsSplit: parsedData['is_split'] == true,
              initialSplitItems: parsedData['split_items'] is List
                  ? (parsedData['split_items'] as List)
                        .whereType<Map>()
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList()
                  : null,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the receipt. Try a clearer photo.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                  .withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white24
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceOption(
                        context: ctx,
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        source: ImageSource.camera,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSourceOption(
                        context: ctx,
                        icon: Icons.image_rounded,
                        label: 'Gallery',
                        source: ImageSource.gallery,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ImageSource source,
    required bool isDark,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: primary, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final hasImage = _pickedImageFile != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          hasImage ? 'Ready to Process' : 'Scan a Receipt',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasImage
                              ? 'Tap "Process Image" to extract expense details'
                              : 'Take a photo or upload from device',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Image Preview Card or Upload Prompt
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? const Color(0xFF1c3326)
                                              : Colors.white)
                                          .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: hasImage
                                    ? _buildImagePreview(isDark, primaryColor)
                                    : _buildUploadPrompt(isDark, primaryColor),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bottom action button
                        _buildActionButton(primaryColor, isDark, hasImage),
                        const SizedBox(height: 8),
                      ],
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

  // Shows the picked image with a retake button overlay
  Widget _buildImagePreview(bool isDark, Color primary) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: Image.file(_pickedImageFile!, fit: BoxFit.cover),
        ),
        // Loading overlay
        if (_isProcessing)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(31),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primary, strokeWidth: 3),
                const SizedBox(height: 20),
                Text(
                  'Reading receipt...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        // Retake button in top-right corner
        if (!_isProcessing)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _showSourceSheet,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Retake',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Empty state — upload prompt
  Widget _buildUploadPrompt(bool isDark, Color primary) {
    return GestureDetector(
      onTap: _showSourceSheet,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUploadIcon(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                primary: primary,
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
              ),
              _buildUploadIcon(
                icon: Icons.image_rounded,
                label: 'Gallery',
                primary: primary,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(
                'AI powered receipt parser',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              size: 28,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            'SCAN RECEIPT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildUploadIcon({
    required IconData icon,
    required String label,
    required Color primary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: primary, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Color primary, bool isDark, bool hasImage) {
    return Material(
      color: hasImage && !_isProcessing
          ? primary
          : isDark
          ? Colors.white12
          : Colors.black12,
      borderRadius: BorderRadius.circular(24),
      elevation: hasImage && !_isProcessing ? 8 : 0,
      shadowColor: primary.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: hasImage && !_isProcessing
            ? _processImage
            : (!hasImage ? _showSourceSheet : null),
        child: Container(
          width: double.infinity,
          height: 64,
          alignment: Alignment.center,
          child: _isProcessing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasImage ? 'Process Image' : 'Choose Image',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: hasImage
                            ? (isDark
                                  ? const Color(0xFF102217)
                                  : const Color(0xFF0F172A))
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      hasImage
                          ? Icons.auto_awesome_rounded
                          : Icons.arrow_forward_rounded,
                      color: hasImage
                          ? (isDark
                                ? const Color(0xFF102217)
                                : const Color(0xFF0F172A))
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
