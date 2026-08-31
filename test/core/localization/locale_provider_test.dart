import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/localization/locale_provider.dart';
import 'package:jaswallet_app/core/localization/supported_locales.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── SupportedLocales static helpers ─────────────────────────────────────────

  group('SupportedLocales', () {
    test('contains exactly 3 locales', () {
      expect(SupportedLocales.all.length, 3);
    });

    test('includes russian, english, kazakh', () {
      expect(SupportedLocales.all, contains(SupportedLocales.russian));
      expect(SupportedLocales.all, contains(SupportedLocales.english));
      expect(SupportedLocales.all, contains(SupportedLocales.kazakh));
    });

    test('default locale is Russian', () {
      expect(SupportedLocales.defaultLocale, SupportedLocales.russian);
    });

    test('getLanguageName returns correct name for each locale', () {
      expect(SupportedLocales.getLanguageName(SupportedLocales.russian), 'Русский');
      expect(SupportedLocales.getLanguageName(SupportedLocales.english), 'English');
      expect(SupportedLocales.getLanguageName(SupportedLocales.kazakh), 'Қазақша');
    });

    test('getLanguageName returns languageCode for unknown locale', () {
      expect(SupportedLocales.getLanguageName(const Locale('fr')), 'fr');
    });

    test('getLanguageCode returns uppercase 2-letter code', () {
      expect(SupportedLocales.getLanguageCode(SupportedLocales.russian), 'RU');
      expect(SupportedLocales.getLanguageCode(SupportedLocales.english), 'EN');
      expect(SupportedLocales.getLanguageCode(SupportedLocales.kazakh), 'KK');
    });

    test('findByCode returns correct locale for each code', () {
      expect(SupportedLocales.findByCode('ru'), SupportedLocales.russian);
      expect(SupportedLocales.findByCode('en'), SupportedLocales.english);
      expect(SupportedLocales.findByCode('kk'), SupportedLocales.kazakh);
    });

    test('findByCode is case-insensitive', () {
      expect(SupportedLocales.findByCode('RU'), SupportedLocales.russian);
      expect(SupportedLocales.findByCode('EN'), SupportedLocales.english);
      expect(SupportedLocales.findByCode('KK'), SupportedLocales.kazakh);
    });

    test('findByCode returns null for unsupported code', () {
      expect(SupportedLocales.findByCode('fr'), isNull);
      expect(SupportedLocales.findByCode('de'), isNull);
      expect(SupportedLocales.findByCode(''), isNull);
    });

    test('getFlag returns correct flag emoji', () {
      expect(SupportedLocales.getFlag(SupportedLocales.russian), '🇷🇺');
      expect(SupportedLocales.getFlag(SupportedLocales.english), '🇺🇸');
      expect(SupportedLocales.getFlag(SupportedLocales.kazakh), '🇰🇿');
    });

    test('getFlag returns globe for unknown locale', () {
      expect(SupportedLocales.getFlag(const Locale('fr')), '🌐');
    });
  });

  // ── LocaleNotifier state transitions ────────────────────────────────────────

  group('LocaleNotifier — state transitions', () {
    test('initial state is Russian (default)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('setEnglish() changes state to English', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setEnglish();

      expect(container.read(localeProvider), SupportedLocales.english);
    });

    test('setRussian() changes state to Russian', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setEnglish();
      container.read(localeProvider.notifier).setRussian();

      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('setKazakh() changes state to Kazakh', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setKazakh();

      expect(container.read(localeProvider), SupportedLocales.kazakh);
    });

    test('setLocale() with English Locale object works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setLocale(const Locale('en'));

      expect(container.read(localeProvider), SupportedLocales.english);
    });

    test('setLocale() with unsupported code is a no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setRussian();
      container.read(localeProvider.notifier).setLocale(const Locale('fr'));

      // State unchanged
      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('currentLanguageCode returns correct code after switch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setKazakh();

      expect(container.read(localeProvider.notifier).currentLanguageCode, 'kk');
    });

    test('currentLanguageName returns correct name after switch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).setEnglish();

      expect(container.read(localeProvider.notifier).currentLanguageName, 'English');
    });
  });

  // ── LocaleNotifier persistence ───────────────────────────────────────────────
  //
  // Persistence is tested by pre-populating SharedPreferences and verifying the
  // notifier loads the correct value on initialization. This avoids race
  // conditions from fire-and-forget saves that are not awaited by callers.

  group('LocaleNotifier — persistence', () {
    test('loads English from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider); // trigger lazy initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(localeProvider), SupportedLocales.english);
    });

    test('loads Kazakh from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'kk'});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(localeProvider), SupportedLocales.kazakh);
    });

    test('loads Russian from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ru'});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('falls back to Russian default when no locale stored', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('falls back to default when persisted code is invalid', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'xyz'});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Invalid code — stays at default Russian
      expect(container.read(localeProvider), SupportedLocales.russian);
    });

    test('setEnglish() updates SharedPreferences key', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setEnglish();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'en');
    });

    test('setKazakh() updates SharedPreferences key', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setKazakh();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'kk');
    });
  });
}
