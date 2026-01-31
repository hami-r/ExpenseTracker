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
    ThemeOption(name: 'Emerald Green', color: const Color(0xFF14b8a6)),
    ThemeOption(name: 'Royal Blue', color: const Color(0xFF2563eb)),
    ThemeOption(name: 'Sunset Orange', color: const Color(0xFFf97316)),
    ThemeOption(name: 'Mint Green', color: const Color(0xFF10b981)),
    ThemeOption(name: 'Deep Purple', color: const Color(0xFF9333ea)),
    ThemeOption(name: 'Neon Rose', color: const Color(0xFFf43f5e)),
    ThemeOption(name: 'Midnight Black', color: const Color(0xFF1f2937)),
    ThemeOption(name: 'Hot Pink', color: const Color(0xFFec4899)),
    ThemeOption(name: 'Crimson Red', color: const Color(0xFFdc2626)),
    ThemeOption(name: 'Electric Cyan', color: const Color(0xFF06b6d4)),
    ThemeOption(name: 'Golden Yellow', color: const Color(0xFFfbbf24)),
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
                        const SizedBox(height: 32),
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
              color: theme.color.withOpacity(0.3),
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
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.02),
                      Colors.black.withOpacity(0.02),
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
                          color: Colors.white.withOpacity(0.2),
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
}

class ThemeOption {
  final String name;
  final Color color;

  ThemeOption({required this.name, required this.color});
}
