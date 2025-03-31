import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final String _themeModeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemeMode();
  }

  // Get the current theme mode
  ThemeMode get themeMode => _themeMode;

  // Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Set theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // Set system theme
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Set light theme
  Future<void> useLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set dark theme
  Future<void> useDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Load saved theme mode from preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeIndex = prefs.getInt(_themeModeKey);

      if (savedModeIndex != null && savedModeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedModeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load theme mode: $e');
    }
  }
}
