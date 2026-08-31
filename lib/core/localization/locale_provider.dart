// ignore_for_file: empty_catches
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supported_locales.dart';

const String _localeKey = 'app_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  // [initial] is read synchronously from SharedPreferences in main() before
  // runApp — eliminates the default-locale flash on cold start.
  LocaleNotifier([Locale? initial]) : super(initial ?? SupportedLocales.defaultLocale);

  Future<void> _saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {}
  }

  void setRussian() {
    state = SupportedLocales.russian;
    _saveLocale(state);
  }

  void setEnglish() {
    state = SupportedLocales.english;
    _saveLocale(state);
  }

  void setKazakh() {
    state = SupportedLocales.kazakh;
    _saveLocale(state);
  }

  void setLocale(Locale locale) {
    final fullLocale = SupportedLocales.findByCode(locale.languageCode);
    if (fullLocale != null) {
      state = fullLocale;
      _saveLocale(state);
    }
  }

  String get currentLanguageCode => state.languageCode;
  String get currentLanguageName => SupportedLocales.getLanguageName(state);
}
