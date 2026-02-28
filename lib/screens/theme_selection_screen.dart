import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String _selectedTheme = 'Emerald Green';
  String _appliedTheme = 'Emerald Green'; // Track what's actually applied
  bool _showSmallSquares = true;

  @override
  void initState() {
    super.initState();
    // Load the current theme from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _appliedTheme = themeProvider.getCurrentThemeName();
        _selectedTheme = _appliedTheme;
      });
    });
  }

  List<ThemeOption> get _allThemes => [
    ...ThemeProvider.themeColors.entries.map(
      (entry) => ThemeOption(name: entry.key, color: entry.value),
    ),
  ];

  List<ThemeOption> get _themes {
    // Find the applied theme (what's currently active)
    final applied = _allThemes.firstWhere(
      (theme) => theme.name == _appliedTheme,
      orElse: () => _allThemes.first,
    );

    // Create applied option with current theme color
    final appliedWithThemeColor = ThemeOption(
      name: applied.name,
      color: Theme.of(context).colorScheme.primary,
    );

    // Filter out the applied theme from others
    final others = _allThemes
        .where((theme) => theme.name != _appliedTheme)
        .toList();

    // Return applied first, then others
    return [appliedWithThemeColor, ...others];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(isDark),
                        const SizedBox(height: 20),
                        _buildViewToggle(isDark),
                        const SizedBox(height: 20),
                        _buildThemeGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply theme via ThemeProvider
                      final themeProvider = Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      );
                      themeProvider.setThemeByName(_selectedTheme);
                      setState(() {
                        _appliedTheme = _selectedTheme;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0f172a),
                      foregroundColor: isDark
                          ? const Color(0xFF0f172a)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Apply Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
            ),
          ),
          Text(
            'Choose Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 40), // Placeholder for alignment
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Splash',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0f172a),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a vibrant color theme for your interface.',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeGrid() {
    if (_showSmallSquares) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _themes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) =>
            _buildSmallSquareThemeCard(_themes[index]),
      );
    }

    return Column(
      children: _themes.map((theme) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildThemeCard(theme),
        );
      }).toList(),
    );
  }

  Widget _buildThemeCard(ThemeOption theme) {
    final isSelected = _selectedTheme == theme.name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme.name;
        });
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Base color
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Glass overlay effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.02),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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

  Widget _buildSmallSquareThemeCard(ThemeOption theme) {
    final isSelected = _selectedTheme == theme.name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme.name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: theme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.color.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: Colors.white.withValues(
                    alpha: isSelected ? 0.95 : 0.55,
                  ),
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                theme.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : const Color(0xFFe5e7eb),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Small Squares',
              selected: _showSmallSquares,
              isDark: isDark,
              onTap: () => setState(() => _showSmallSquares = true),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildToggleButton(
              label: 'Large Cards',
              selected: !_showSmallSquares,
              isDark: isDark,
              onTap: () => setState(() => _showSmallSquares = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF111827) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF0f172a))
                : (isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b)),
          ),
        ),
      ),
    );
  }
}

class ThemeOption {
  final String name;
  final Color color;

  ThemeOption({required this.name, required this.color});
}
