import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/services/ai_service.dart';
import '../database/services/category_service.dart';
import '../database/services/payment_method_service.dart';
import '../database/services/user_service.dart';
import '../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'add_expense_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class NaturalLanguageEntryScreen extends StatefulWidget {
  const NaturalLanguageEntryScreen({super.key});

  @override
  State<NaturalLanguageEntryScreen> createState() =>
      _NaturalLanguageEntryScreenState();
}

class _NaturalLanguageEntryScreenState
    extends State<NaturalLanguageEntryScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isListening = false;
  bool _shouldKeepListening = false;
  bool _isStartingListening = false;
  bool _isManualStop = false;
  bool _restartScheduled = false;
  Timer? _listenWatchdog;
  bool _isProcessing = false;
  bool _speechEnabled = false;
  String _committedTranscript = '';
  String _sessionTranscript = '';
  DateTime? _lastSpeechEventAt;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
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
    _initSpeech();
  }

  void _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (val) {
          final currentlyListening = (val == 'listening');
          if (mounted) {
            setState(() {
              // The plugin emits 'listening' when active, 'notListening' or 'done' when stopped.
              _isListening = currentlyListening;
              if (currentlyListening) {
                _lastSpeechEventAt = DateTime.now();
              }
            });
          }
          if (!currentlyListening &&
              _shouldKeepListening &&
              !_isManualStop &&
              _speechEnabled) {
            _commitSessionTranscript();
            _scheduleListeningRestart();
          }
        },
        onError: (val) {
          debugPrint('Speech recognition error: $val');
          if (mounted) setState(() => _isListening = false);
          if (_shouldKeepListening && !_isManualStop && _speechEnabled) {
            _commitSessionTranscript();
            _scheduleListeningRestart();
          }
        },
      );
      if (mounted) setState(() {});
    }
  }

  void _scheduleListeningRestart() {
    if (_restartScheduled || !_speechEnabled) return;
    _restartScheduled = true;
    Future.delayed(const Duration(milliseconds: 450), () {
      _restartScheduled = false;
      if (!mounted ||
          !_shouldKeepListening ||
          _isManualStop ||
          _isListening ||
          _isStartingListening) {
        return;
      }
      _startListening();
    });
  }

  String _joinTranscript(String committed, String currentSession) {
    final left = committed.trim();
    final right = currentSession.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    return '$left $right';
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

    if (_committedTranscript.isEmpty) {
      _committedTranscript = chunk;
    } else if (!_committedTranscript.endsWith(chunk)) {
      _committedTranscript = '$_committedTranscript $chunk'.trim();
    }

    _sessionTranscript = '';
    _updateInputFromTranscripts();
  }

  void _startListenWatchdog() {
    _listenWatchdog?.cancel();
    _listenWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_speechEnabled) return;
      if (_shouldKeepListening && !_isListening && !_isStartingListening) {
        _startListening();
        return;
      }

      // Some devices report "listening" but stop producing events after silence.
      final lastEvent = _lastSpeechEventAt;
      if (_shouldKeepListening &&
          _isListening &&
          !_isStartingListening &&
          lastEvent != null &&
          DateTime.now().difference(lastEvent) > const Duration(seconds: 7)) {
        _forceRefreshListeningSession();
      }
    });
  }

  void _stopListenWatchdog() {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
  }

  Future<void> _forceRefreshListeningSession() async {
    if (!_shouldKeepListening || _isManualStop || _isStartingListening) return;
    _isStartingListening = true;
    try {
      await _speechToText.cancel();
    } catch (_) {
      // Best-effort reset only.
    } finally {
      _isStartingListening = false;
    }
    _scheduleListeningRestart();
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isListening || _isStartingListening) return;
    _isStartingListening = true;
    _isManualStop = false;
    _lastSpeechEventAt = DateTime.now();
    _syncCommittedFromInput();
    _sessionTranscript = '';
    if (mounted) {
      setState(() {
        _shouldKeepListening = true;
      });
    }
    _startListenWatchdog();
    try {
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              final recognized = result.recognizedWords.trim();
              if (recognized.isEmpty) return;
              _lastSpeechEventAt = DateTime.now();
              _sessionTranscript = recognized;
              _updateInputFromTranscripts();
              if (result.finalResult) {
                _commitSessionTranscript();
              }
            });
          }
        },
        // Keep listening until user manually stops (practically long timeout).
        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(minutes: 10),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (_shouldKeepListening && !_isManualStop) {
        _scheduleListeningRestart();
      }
    } finally {
      _isStartingListening = false;
    }
  }

  Future<void> _stopListening() async {
    _isManualStop = true;
    if (mounted) {
      setState(() {
        _shouldKeepListening = false;
      });
    }
    _commitSessionTranscript();
    _stopListenWatchdog();
    _lastSpeechEventAt = null;
    if (_isListening || _isStartingListening) {
      await _speechToText.stop();
    } else {
      await _speechToText.cancel();
    }
  }

  Future<void> _clearInput() async {
    final shouldResumeListening = _shouldKeepListening || _isListening;

    if (shouldResumeListening) {
      await _stopListening();
    }

    if (!mounted) return;
    setState(() {
      _inputController.clear();
      _committedTranscript = '';
      _sessionTranscript = '';
      _lastSpeechEventAt = null;
      _interpretedAmount = null;
      _interpretedCategory = null;
      _interpretedMethod = null;
    });

    if (shouldResumeListening) {
      await _startListening();
    }
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
    _stopListenWatchdog();
    _speechToText.stop();
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
      height: 160,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Microphone Section
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_shouldKeepListening || _isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Inner Circle/Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: (_shouldKeepListening || _isListening)
                            ? primary.withValues(alpha: 0.8)
                            : primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 36,
                        color: Color(0xFF102217),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (_shouldKeepListening || _isListening) ? 1.0 : 0.5,
                child: Text(
                  (_shouldKeepListening || _isListening)
                      ? 'Listening... (tap again to stop)'
                      : 'Tap to speak',
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
}
