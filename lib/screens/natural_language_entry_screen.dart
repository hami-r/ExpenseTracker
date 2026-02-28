import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/services/ai_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'add_expense_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class NaturalLanguageEntryScreen extends StatefulWidget {
  const NaturalLanguageEntryScreen({super.key});

  @override
  State<NaturalLanguageEntryScreen> createState() =>
      _NaturalLanguageEntryScreenState();
}

class _NaturalLanguageEntryScreenState extends State<NaturalLanguageEntryScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _speechControlChannel = MethodChannel(
    'expense_tracker_ai/speech_control',
  );
  static const EventChannel _speechEventsChannel = EventChannel(
    'expense_tracker_ai/speech_events',
  );

  final TextEditingController _inputController = TextEditingController();
  bool _isListening = false;
  bool _isStartingListening = false;
  bool _isMicPressed = false;
  bool _isProcessing = false;
  bool _speechEnabled = false;
  String _committedTranscript = '';
  String _sessionTranscript = '';
  double _audioLevel = 0;
  StreamSubscription<dynamic>? _speechEventsSubscription;
  late final AnimationController _micPulseController;
  final _aiService = AIService(CategoryService(), PaymentMethodService());
  final _userService = UserService();

  // Mock interpreted values for UI demonstration
  String? _interpretedAmount;
  String? _interpretedCategory;
  String? _interpretedMethod;
  final IconData _categoryIcon = Icons.auto_awesome_rounded;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initSpeech();
  }

  bool get _isActivelyListening => _isMicPressed || _isListening;

  void _syncMicAnimation() {
    if (_isActivelyListening) {
      if (!_micPulseController.isAnimating) {
        _micPulseController.repeat();
      }
      return;
    }

    if (_micPulseController.isAnimating) {
      _micPulseController.stop();
    }
    _micPulseController.value = 0;
  }

  Future<void> _initSpeech() async {
    if (!Platform.isAndroid) {
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _speechEventsSubscription?.cancel();
    _speechEventsSubscription = _speechEventsChannel
        .receiveBroadcastStream()
        .listen(
          _handleSpeechEvent,
          onError: (error) {
            debugPrint('Native speech stream error: $error');
            if (mounted) {
              setState(() => _isListening = false);
            }
          },
        );

    try {
      final available =
          await _speechControlChannel.invokeMethod<bool>('isAvailable') ??
          false;
      if (mounted) {
        setState(() => _speechEnabled = available);
      }
    } catch (e) {
      debugPrint('Native speech init failed: $e');
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
    }
  }

  void _handleSpeechEvent(dynamic event) {
    if (event is! Map) return;
    final data = Map<String, dynamic>.from(event);
    final type = data['type']?.toString();
    if (type == null) return;

    switch (type) {
      case 'status':
        final status = data['status']?.toString() ?? '';
        final listening = status == 'listening' || status == 'ready';
        if (mounted) {
          setState(() {
            _isListening = listening;
            if (!listening) {
              _audioLevel = 0;
            }
          });
        }
        _syncMicAnimation();
        break;
      case 'result':
        final recognized = (data['text']?.toString() ?? '').trim();
        if (recognized.isEmpty || !mounted) return;
        setState(() {
          _sessionTranscript = recognized;
          _updateInputFromTranscripts();
          if (data['final'] == true) {
            _commitSessionTranscript();
          }
        });
        break;
      case 'rms':
        final nextLevel = ((data['value'] as num?)?.toDouble() ?? 0).clamp(
          0.0,
          1.0,
        );
        if (!mounted || !_isActivelyListening) return;
        setState(() {
          _audioLevel = (_audioLevel * 0.65) + (nextLevel * 0.35);
        });
        break;
      case 'error':
        final message = data['message']?.toString() ?? 'Speech error';
        debugPrint('Native speech error: $message');
        if (mounted) {
          setState(() {
            _isListening = false;
            _audioLevel = 0;
          });
        }
        _syncMicAnimation();
        break;
    }
  }

  String _joinTranscript(String committed, String currentSession) {
    final left = committed.trim();
    final right = currentSession.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    return '$left $right';
  }

  String _normalizeTranscript(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _syncCommittedFromInput() {
    _committedTranscript = _inputController.text.trim();
  }

  void _updateInputFromTranscripts() {
    final combined = _joinTranscript(_committedTranscript, _sessionTranscript);
    if (_inputController.text == combined) return;
    _inputController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
      composing: TextRange.empty,
    );
  }

  void _commitSessionTranscript() {
    final chunk = _sessionTranscript.trim();
    if (chunk.isEmpty) return;

    final normalizedChunk = _normalizeTranscript(chunk);
    if (normalizedChunk.isEmpty) {
      _sessionTranscript = '';
      _updateInputFromTranscripts();
      return;
    }

    final normalizedCommitted = _normalizeTranscript(_committedTranscript);

    if (_committedTranscript.isEmpty) {
      _committedTranscript = chunk;
    } else if (!normalizedCommitted.endsWith(normalizedChunk)) {
      _committedTranscript = '$_committedTranscript $chunk'.trim();
    }

    _sessionTranscript = '';
    _updateInputFromTranscripts();
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isStartingListening) return;
    _isStartingListening = true;
    _syncCommittedFromInput();
    _sessionTranscript = '';
    _syncMicAnimation();
    try {
      final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
      await _speechControlChannel.invokeMethod('startListening', {
        if (locale != null) 'locale': locale,
      });
    } catch (e) {
      debugPrint('Error starting native speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _audioLevel = 0;
        });
      }
      _syncMicAnimation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to start voice recognition')),
        );
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> _stopListening() async {
    if (mounted) {
      setState(() {
        _audioLevel = 0;
      });
    }
    _commitSessionTranscript();
    try {
      await _speechControlChannel.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('Error stopping native speech recognition: $e');
    }
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
    _syncMicAnimation();
  }

  Future<void> _handleMicPressStart() async {
    if (_isMicPressed || _isProcessing) return;
    if (mounted) {
      setState(() {
        _isMicPressed = true;
      });
    }
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
    await _startListening();
  }

  Future<void> _handleMicPressEnd() async {
    if (!_isMicPressed) return;
    if (mounted) {
      setState(() {
        _isMicPressed = false;
      });
    }
    await HapticFeedback.selectionClick();
    await SystemSound.play(SystemSoundType.click);
    await _stopListening();
  }

  Future<void> _clearInput() async {
    if (_isActivelyListening) {
      await _stopListening();
    }

    if (!mounted) return;
    setState(() {
      _inputController.clear();
      _committedTranscript = '';
      _sessionTranscript = '';
      _audioLevel = 0;
      _interpretedAmount = null;
      _interpretedCategory = null;
      _interpretedMethod = null;
    });
  }

  Future<void> _processText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final user = await _userService.getCurrentUser();
      if (user == null || user.userId == null) {
        throw Exception('User not logged in');
      }
      if (!mounted) return;

      final profileId = context.read<ProfileProvider>().activeProfileId;
      final parsedData = await _aiService.parseNaturalLanguageExpense(
        text,
        user.userId!,
        profileId: profileId,
      );

      if (parsedData != null && mounted) {
        final saved = await Navigator.push<bool>(
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
        if (saved == true && mounted) {
          Navigator.pop(context, true);
        }
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

  @override
  void dispose() {
    _speechEventsSubscription?.cancel();
    if (Platform.isAndroid) {
      _speechControlChannel.invokeMethod('destroy');
    }
    _micPulseController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Decorative Blobs
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

          // Grain Effect (Removed due to SVG loading issues)
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Expanded(child: _buildInputSection(isDark)),
                        if (_interpretedAmount != null)
                          _buildInterpretationSection(isDark, primaryColor),
                        const SizedBox(height: 32),
                        _buildBottomActions(primaryColor, isDark),
                        const SizedBox(height: 16),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
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
            'NEW ENTRY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          IconButton(
            onPressed: () {
              // History logic
            },
            icon: Icon(
              Icons.history_rounded,
              size: 24,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 40),
      child: TextField(
        controller: _inputController,
        maxLines: null,
        autofocus: true,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          height: 1.2,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Tell me what happened...',
          hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildInterpretationSection(bool isDark, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Text(
                'I UNDERSTOOD:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1c3326) : Colors.white)
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      'Amount',
                      _interpretedAmount ?? "0.00",
                      Icons.currency_rupee_rounded,
                      Colors.green,
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(
                      'Category',
                      _interpretedCategory ?? "General",
                      _categoryIcon,
                      Colors.orange,
                      isDark,
                    ),
                    const SizedBox(width: 12),
                    _buildChip(
                      'Method',
                      _interpretedMethod ?? "Cash",
                      Icons.qr_code_scanner_rounded,
                      Colors.blue,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Color primary, bool isDark) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Microphone Section
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMicButton(primary, isDark),
              const SizedBox(height: 8),
              _buildVoiceBars(primary, isDark),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isActivelyListening ? 1.0 : 0.5,
                child: Text(
                  _isMicPressed
                      ? 'Recording... release to add text'
                      : _isActivelyListening
                      ? 'Listening... (release to stop)'
                      : 'Hold to speak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          // Confirm Button
          Positioned(
            left: 0,
            bottom: 40,
            child: Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              elevation: 8,
              child: InkWell(
                onTap: _clearInput,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            right: 0,
            bottom: 40,
            child: Material(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(100),
              elevation: 8,
              child: InkWell(
                onTap: _isProcessing ? null : _processText,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 56,
                  height: 56,
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
                      : Icon(
                          Icons.check_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 28,
                          weight: 700,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(Color primary, bool isDark) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _handleMicPressStart(),
      onPointerUp: (_) => _handleMicPressEnd(),
      onPointerCancel: (_) => _handleMicPressEnd(),
      child: SizedBox(
        width: 132,
        height: 132,
        child: AnimatedBuilder(
          animation: _micPulseController,
          builder: (context, child) {
            final pulse = _micPulseController.value;
            final delayedPulse = (pulse + 0.45) % 1.0;
            final level = _isActivelyListening ? _audioLevel : 0;
            final baseButtonSize = 82.0;
            final sizeBoost = level * 16;

            return Stack(
              alignment: Alignment.center,
              children: [
                _buildPulseRing(
                  color: primary,
                  pulse: pulse,
                  baseSize: 94,
                  maxGrowth: 34,
                  maxOpacity: 0.26,
                ),
                _buildPulseRing(
                  color: primary,
                  pulse: delayedPulse,
                  baseSize: 84,
                  maxGrowth: 26,
                  maxOpacity: 0.18,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  width: baseButtonSize + sizeBoost,
                  height: baseButtonSize + sizeBoost,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isActivelyListening
                          ? [primary.withValues(alpha: 0.85), primary]
                          : [primary, primary.withValues(alpha: 0.88)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(
                          alpha: _isActivelyListening ? 0.45 : 0.28,
                        ),
                        blurRadius: _isActivelyListening ? 34 : 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: _isMicPressed ? 0.92 : 1.0,
                    child: Icon(
                      _isActivelyListening
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_rounded,
                      size: 36,
                      color: const Color(0xFF102217),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPulseRing({
    required Color color,
    required double pulse,
    required double baseSize,
    required double maxGrowth,
    required double maxOpacity,
  }) {
    final isActive = _isActivelyListening;
    final easedPulse = Curves.easeOut.transform(pulse);
    final size = baseSize + (easedPulse * maxGrowth);
    final opacity = (isActive ? (1 - easedPulse) * maxOpacity : 0.0)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildVoiceBars(Color primary, bool isDark) {
    return SizedBox(
      height: 18,
      width: 72,
      child: AnimatedBuilder(
        animation: _micPulseController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              final phase =
                  (_micPulseController.value + (index * 0.13)) * 2 * math.pi;
              final wave = (math.sin(phase) + 1) / 2;
              final liveFactor = _isActivelyListening ? _audioLevel : 0;
              final height = 4 + ((wave * 7) + (liveFactor * 7));
              return AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: _isActivelyListening
                      ? primary.withValues(alpha: 0.9)
                      : (isDark ? Colors.white30 : Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
