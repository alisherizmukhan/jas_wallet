// ignore_for_file: empty_catches
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeKey = 'theme_mode';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // [initial] is read synchronously from SharedPreferences in main() before
  // runApp so no async gap — eliminates the light-flash on dark-mode cold start.
  ThemeNotifier([ThemeMode? initial]) : super(initial ?? ThemeMode.light);

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {}
  }

  void setLightMode() {
    state = ThemeMode.light;
    _saveTheme(state);
  }

  void setDarkMode() {
    state = ThemeMode.dark;
    _saveTheme(state);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setDarkMode();
    } else {
      setLightMode();
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _saveTheme(state);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
