import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_history_screen.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final TextEditingController _newKeyNameController = TextEditingController();
  final TextEditingController _newKeyValueController = TextEditingController();

  List<Map<String, dynamic>> _apiKeys = [];
  String? _activeKeyId;

  bool _voiceEnabled = true;
  bool _insightsEnabled = true;
  bool _receiptEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keysJson = prefs.getString('ai_api_keys_list') ?? '[]';
    final List<dynamic> decoded = jsonDecode(keysJson);

    setState(() {
      _apiKeys = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      _activeKeyId = prefs.getString('active_ai_key_id');

      // Fallback for old single key storage if it exists and list is empty
      final oldKey = prefs.getString('gemini_api_key');
      if (oldKey != null && oldKey.isNotEmpty && _apiKeys.isEmpty) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        _apiKeys.add({'id': id, 'name': 'Default Key', 'key': oldKey});
        _activeKeyId = id;
      }

      _voiceEnabled = prefs.getBool('ai_voice_enabled') ?? true;
      _insightsEnabled = prefs.getBool('ai_insights_enabled') ?? true;
      _receiptEnabled = prefs.getBool('ai_receipt_enabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('ai_api_keys_list', jsonEncode(_apiKeys));
    if (_activeKeyId != null) {
      await prefs.setString('active_ai_key_id', _activeKeyId!);
      // Maintain backward compatibility for the currently active key
      final activeKey = _apiKeys.firstWhere(
        (k) => k['id'] == _activeKeyId,
        orElse: () => {'key': ''},
      )['key'];
      await prefs.setString('gemini_api_key', activeKey);
    }

    await prefs.setBool('ai_voice_enabled', _voiceEnabled);
    await prefs.setBool('ai_insights_enabled', _insightsEnabled);
    await prefs.setBool('ai_receipt_enabled', _receiptEnabled);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Configuration Saved Successfully'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  void _showKeyDialog({Map<String, dynamic>? keyToEdit}) {
    if (keyToEdit != null) {
      _newKeyNameController.text = keyToEdit['name'];
      _newKeyValueController.text = keyToEdit['key'];
    } else {
      _newKeyNameController.clear();
      _newKeyValueController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            keyToEdit == null ? 'Add New API Key' : 'Edit API Key',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newKeyNameController,
                decoration: InputDecoration(
                  labelText: 'Key Label (e.g. Work)',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newKeyValueController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newKeyNameController.clear();
                _newKeyValueController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_newKeyNameController.text.isNotEmpty &&
                    _newKeyValueController.text.isNotEmpty) {
                  setState(() {
                    if (keyToEdit == null) {
                      final id = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      _apiKeys.add({
                        'id': id,
                        'name': _newKeyNameController.text.trim(),
                        'key': _newKeyValueController.text.trim(),
                      });
                      _activeKeyId ??= id;
                    } else {
                      final index = _apiKeys.indexWhere(
                        (k) => k['id'] == keyToEdit['id'],
                      );
                      if (index != -1) {
                        _apiKeys[index] = {
                          'id': keyToEdit['id'],
                          'name': _newKeyNameController.text.trim(),
                          'key': _newKeyValueController.text.trim(),
                        };
                      }
                    }
                    _newKeyNameController.clear();
                    _newKeyValueController.clear();
                  });
                  Navigator.pop(context);
                  _saveSettings(); // Auto-save to SharedPreferences
                }
              },
              child: Text(keyToEdit == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteKey(String id) {
    setState(() {
      _apiKeys.removeWhere((k) => k['id'] == id);
      if (_activeKeyId == id) {
        _activeKeyId = _apiKeys.isNotEmpty ? _apiKeys.first['id'] : null;
      }
    });
    _saveSettings(); // Auto-save to SharedPreferences
  }

  @override
  void dispose() {
    _newKeyNameController.dispose();
    _newKeyValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor =
        Theme.of(context).cardTheme.color ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(isDark, primaryColor, surfaceColor),
                        const SizedBox(height: 32),
                        _buildKeysListSection(
                          isDark,
                          primaryColor,
                          surfaceColor,
                        ),
                        const SizedBox(height: 32),
                        _buildFeaturesSection(
                          isDark,
                          primaryColor,
                          surfaceColor,
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomButton(primaryColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 28,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            'AI CONFIGURATION',
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

  Widget _buildHeroCard(bool isDark, Color primary, Color surface) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.6 : 0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Icon(
              Icons.smart_toy_rounded,
              size: 120,
              color: primary.withValues(alpha: 0.08),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.vpn_key_rounded, color: primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Multi-Key Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Store multiple Gemini API keys and switch between them instantly. Only the active key is used for AI processing.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeysListSection(bool isDark, Color primary, Color surface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'MANAGED KEYS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showKeyDialog(),
              icon: Icon(Icons.add_rounded, size: 18, color: primary),
              label: Text(
                'Add Key',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        if (_apiKeys.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFf1f5f9),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.key_off_rounded,
                  size: 48,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 16),
                Text(
                  'No API keys added yet',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFf1f5f9),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _apiKeys.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.white10 : Colors.black12,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final keyData = _apiKeys[index];
                final keyStr = keyData['key'] as String;
                final maskedKey = keyStr.length > 8
                    ? '${keyStr.substring(0, 4)}••••${keyStr.substring(keyStr.length - 4)}'
                    : '••••••••';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Radio<String>(
                    value: keyData['id'],
                    groupValue: _activeKeyId,
                    activeColor: primary,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return primary;
                      return isDark ? Colors.white24 : Colors.black12;
                    }),
                    onChanged: (val) {
                      setState(() => _activeKeyId = val);
                      _saveSettings();
                    },
                  ),
                  title: Text(
                    keyData['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    maskedKey,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 20,
                        ),
                        onPressed: () => _showKeyDialog(keyToEdit: keyData),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _deleteKey(keyData['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection(bool isDark, Color primary, Color surface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ENABLED FEATURES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        _buildFeatureToggle(
          'Voice Entry',
          'Natural language processing',
          Icons.mic_rounded,
          Theme.of(context).colorScheme.tertiary,
          _voiceEnabled,
          (val) => setState(() => _voiceEnabled = val),
          isDark,
          surface,
        ),
        const SizedBox(height: 12),
        _buildFeatureToggle(
          'Smart Insights',
          'Spending patterns & advice',
          Icons.insights_rounded,
          Colors.purpleAccent,
          _insightsEnabled,
          (val) => setState(() => _insightsEnabled = val),
          isDark,
          surface,
        ),
        const SizedBox(height: 12),
        _buildFeatureToggle(
          'Receipt Scanning',
          'Extract data from photos',
          Icons.receipt_long_rounded,
          Theme.of(context).colorScheme.secondary,
          _receiptEnabled,
          (val) => setState(() => _receiptEnabled = val),
          isDark,
          surface,
        ),
        const SizedBox(height: 32),
        _buildHistoryAccessCard(isDark, primary, surface),
      ],
    );
  }

  Widget _buildHistoryAccessCard(bool isDark, Color primary, Color surface) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interaction History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'View past AI conversations and scans',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIHistoryScreen(),
                ),
              );
            },
            child: const Text('VIEW'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool value,
    Function(bool) onChanged,
    bool isDark,
    Color surface,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFf1f5f9),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            inactiveThumbColor: isDark ? Colors.white24 : Colors.white,
            inactiveTrackColor: isDark
                ? Colors.white10
                : const Color(0xFFf1f5f9),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return isDark ? Colors.white10 : const Color(0xFFf1f5f9);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: isDark ? Colors.black87 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: isDark ? Colors.black87 : Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Validate & Save',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.black87 : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle_rounded, size: 24),
                  ],
                ),
        ),
      ),
    );
  }
}
