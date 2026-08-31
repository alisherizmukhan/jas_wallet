import 'package:flutter/material.dart';

/// Supported locales for the application.
/// Russian (ru), English (en), Kazakh (kk).
class SupportedLocales {
  SupportedLocales._();

  /// Russian locale.
  static const Locale russian = Locale('ru', 'RU');

  /// English locale.
  static const Locale english = Locale('en', 'US');

  /// Kazakh locale.
  static const Locale kazakh = Locale('kk', 'KZ');

  /// Default locale (Russian).
  static const Locale defaultLocale = russian;

  /// List of all supported locales.
  static const List<Locale> all = [
    russian,
    english,
    kazakh,
  ];

  /// Returns the language name for display in UI.
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'kk':
        return 'Қазақша';
      default:
        return locale.languageCode;
    }
  }

  /// Returns a short language code for display (RU, EN, KK).
  static String getLanguageCode(Locale locale) {
    return locale.languageCode.toUpperCase();
  }

  /// Returns the flag emoji for a locale.
  static String getFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return '🇷🇺';
      case 'en':
        return '🇺🇸';
      case 'kk':
        return '🇰🇿';
      default:
        return '🌐';
    }
  }

  /// Finds a locale by language code.
  static Locale? findByCode(String code) {
    try {
      return all.firstWhere(
        (locale) => locale.languageCode == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
