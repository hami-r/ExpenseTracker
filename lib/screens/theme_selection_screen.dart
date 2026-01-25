import 'package:flutter/material.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String _selectedTheme = 'Emerald Green';

  final List<ThemeOption> _themes = [
    ThemeOption(name: 'Emerald Green', color: const Color(0xFF2bb961)),
    ThemeOption(name: 'Royal Blue', color: const Color(0xFF2563eb)),
    ThemeOption(name: 'Sunset Orange', color: const Color(0xFFf97316)),
    ThemeOption(name: 'Mint Green', color: const Color(0xFF10b981)),
    ThemeOption(name: 'Deep Purple', color: const Color(0xFF9333ea)),
    ThemeOption(name: 'Neon Rose', color: const Color(0xFFf43f5e)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF3b82f6,
                ).withOpacity(isDark ? 0.02 : 0.06),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3b82f6).withOpacity(0.1),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFa78bfa,
                ).withOpacity(isDark ? 0.02 : 0.06),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFa78bfa).withOpacity(0.1),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),

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
                      // Apply theme logic here
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
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1a2c26) : Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFe2e8f0),
              ),
            ),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
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
