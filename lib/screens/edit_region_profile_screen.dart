import 'package:flutter/material.dart';
import '../database/services/profile_service.dart';
import '../models/profile.dart';

/// Screen for creating or editing a Region Profile (name, country, currency).
/// Not to be confused with edit_profile_screen.dart which edits user identity.
class EditRegionProfileScreen extends StatefulWidget {
  final int userId;
  final Profile? existing; // null = create new

  const EditRegionProfileScreen({
    super.key,
    required this.userId,
    this.existing,
  });

  @override
  State<EditRegionProfileScreen> createState() =>
      _EditRegionProfileScreenState();
}

class _EditRegionProfileScreenState extends State<EditRegionProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _nameController = TextEditingController();

  List<Map<String, dynamic>> _currencies = [];
  int? _selectedCurrencyId;
  String _selectedCountryCode = '';
  bool _isSaving = false;

  static const List<Map<String, String>> _regions = [
    {'name': 'India', 'code': 'IN'},
    {'name': 'United States', 'code': 'US'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'Europe', 'code': 'EU'},
    {'name': 'United Arab Emirates', 'code': 'AE'},
    {'name': 'Australia', 'code': 'AU'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'Singapore', 'code': 'SG'},
    {'name': 'Japan', 'code': 'JP'},
    {'name': 'China', 'code': 'CN'},
    {'name': 'Germany', 'code': 'DE'},
    {'name': 'France', 'code': 'FR'},
    {'name': 'Brazil', 'code': 'BR'},
    {'name': 'South Africa', 'code': 'ZA'},
    {'name': 'Other', 'code': 'XX'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _selectedCurrencyId = widget.existing!.currencyId;
      _selectedCountryCode = widget.existing!.countryCode ?? '';
    }
    _loadCurrencies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _profileService.getAllCurrencies();
    if (mounted) setState(() => _currencies = currencies);
  }

  String _flagEmoji(String code) {
    if (code.length != 2 || code == 'XX' || code == 'EU') return '🌍';
    return String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => c - 0x41 + 0x1F1E6),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a profile name.');
      return;
    }
    if (_selectedCurrencyId == null) {
      _showSnack('Please select a currency.');
      return;
    }
    setState(() => _isSaving = true);

    final cur = _currencies.firstWhere(
      (c) => c['currency_id'] == _selectedCurrencyId,
      orElse: () => _currencies.first,
    );

    if (widget.existing == null) {
      await _profileService.createProfile(
        Profile(
          userId: widget.userId,
          name: name,
          currencyId: _selectedCurrencyId!,
          countryCode: _selectedCountryCode.isEmpty
              ? null
              : _selectedCountryCode,
          isActive: false,
          currencyCode: cur['currency_code'] as String,
          currencySymbol: cur['symbol'] as String,
          currencyName: cur['currency_name'] as String,
        ),
      );
    } else {
      await _profileService.updateProfile(
        widget.existing!.copyWith(
          name: name,
          currencyId: _selectedCurrencyId,
          countryCode: _selectedCountryCode.isEmpty
              ? null
              : _selectedCountryCode,
          currencyCode: cur['currency_code'] as String,
          currencySymbol: cur['symbol'] as String,
          currencyName: cur['currency_name'] as String,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0f172a),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Profile' : 'New Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1a2c2b) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Profile Name', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: _inp(
                              'e.g. India, UAE, Work',
                              isDark,
                              primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _label('Region', isDark),
                          const SizedBox(height: 8),
                          _dropdownBox(
                            isDark,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedCountryCode.isEmpty
                                    ? null
                                    : _selectedCountryCode,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'Select region',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                dropdownColor: isDark
                                    ? const Color(0xFF1a2c2b)
                                    : Colors.white,
                                items: _regions
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r['code'],
                                        child: Row(
                                          children: [
                                            Text(
                                              _flagEmoji(r['code']!),
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              r['name']!,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0f172a),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(() {
                                  _selectedCountryCode = val ?? '';
                                  if (_nameController.text.isEmpty &&
                                      val != null) {
                                    _nameController.text =
                                        _regions.firstWhere(
                                          (r) => r['code'] == val,
                                          orElse: () => {'name': ''},
                                        )['name'] ??
                                        '';
                                  }
                                }),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _label('Currency', isDark),
                          const SizedBox(height: 8),
                          _dropdownBox(
                            isDark,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedCurrencyId,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'Select currency',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                dropdownColor: isDark
                                    ? const Color(0xFF1a2c2b)
                                    : Colors.white,
                                items: _currencies
                                    .map(
                                      (c) => DropdownMenuItem<int>(
                                        value: c['currency_id'] as int,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  c['symbol'] as String,
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                '${c['currency_name']} (${c['currency_code']})',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0f172a),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCurrencyId = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : Text(
                                isEdit ? 'Save Changes' : 'Create Profile',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isEdit
                                ? 'Changing the currency affects how amounts are displayed. Raw data is never modified.'
                                : 'New profiles start with no transactions, budgets, or payment methods.',
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
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    ),
  );

  Widget _dropdownBox(bool isDark, {required Widget child}) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF243330) : const Color(0xFFf8fafc),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey[200]!,
      ),
    ),
    child: child,
  );

  InputDecoration _inp(String hint, bool isDark, Color primary) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: isDark ? const Color(0xFF243330) : const Color(0xFFf8fafc),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      );
}
