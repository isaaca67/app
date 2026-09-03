import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    setThemeMode(newMode);
  }

  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }
}