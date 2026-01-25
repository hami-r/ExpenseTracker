import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  // Default theme color (Emerald Green)
  Color _primaryColor = const Color(0xFF2bb961);
  bool _isDarkMode = false;

  // Theme color options
  static const Map<String, Color> themeColors = {
    'Emerald Green': Color(0xFF2bb961),
    'Royal Blue': Color(0xFF2563eb),
    'Sunset Orange': Color(0xFFf97316),
    'Mint Green': Color(0xFF10b981),
    'Deep Purple': Color(0xFF9333ea),
    'Neon Rose': Color(0xFFf43f5e),
    'Midnight Black': Color(0xFF1f2937),
    'Hot Pink': Color(0xFFec4899),
    'Crimson Red': Color(0xFFdc2626),
    'Electric Cyan': Color(0xFF06b6d4),
    'Golden Yellow': Color(0xFFfbbf24),
  };

  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => AppTheme.lightTheme(_primaryColor);
  ThemeData get darkTheme => AppTheme.darkTheme(_primaryColor);
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemePreferences();
  }

  // Load saved theme preferences
  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedColorHex = prefs.getString('theme_color');
      final savedDarkMode = prefs.getBool('dark_mode') ?? false;

      if (savedColorHex != null) {
        _primaryColor = Color(int.parse(savedColorHex, radix: 16));
      }
      _isDarkMode = savedDarkMode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  // Save theme preferences
  Future<void> _saveThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_color',
        _primaryColor.value.toRadixString(16),
      );
      await prefs.setBool('dark_mode', _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  // Set primary color by name
  void setThemeByName(String themeName) {
    if (themeColors.containsKey(themeName)) {
      _primaryColor = themeColors[themeName]!;
      _saveThemePreferences();
      notifyListeners();
    }
  }

  // Set primary color directly
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _saveThemePreferences();
    notifyListeners();
  }

  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreferences();
    notifyListeners();
  }

  // Set dark mode
  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveThemePreferences();
    notifyListeners();
  }

  // Get current theme name
  String getCurrentThemeName() {
    for (var entry in themeColors.entries) {
      if (entry.value == _primaryColor) {
        return entry.key;
      }
    }
    return 'Emerald Green'; // Default
  }
}
