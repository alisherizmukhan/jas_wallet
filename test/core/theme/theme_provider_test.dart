import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── ThemeNotifier state transitions ─────────────────────────────────────────

  group('ThemeNotifier — state transitions', () {
    test('initial state is ThemeMode.light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('setDarkMode() changes state to ThemeMode.dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setDarkMode();

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('setLightMode() changes state to ThemeMode.light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setDarkMode();
      container.read(themeProvider.notifier).setLightMode();

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('toggleTheme() switches from light to dark', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).toggleTheme();

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('toggleTheme() switches from dark to light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setDarkMode();
      container.read(themeProvider.notifier).toggleTheme();

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('double toggleTheme() returns to original state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(themeProvider);
      container.read(themeProvider.notifier).toggleTheme();
      container.read(themeProvider.notifier).toggleTheme();

      expect(container.read(themeProvider), initial);
    });

    test('setTheme() accepts ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setTheme(ThemeMode.system);

      expect(container.read(themeProvider), ThemeMode.system);
    });
  });

  // ── ThemeNotifier isDarkMode getter ─────────────────────────────────────────

  group('ThemeNotifier — isDarkMode getter', () {
    test('isDarkMode is false in light mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeProvider.notifier).isDarkMode, isFalse);
    });

    test('isDarkMode is true in dark mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setDarkMode();

      expect(container.read(themeProvider.notifier).isDarkMode, isTrue);
    });

    test('isDarkMode is false for ThemeMode.system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeProvider.notifier).setTheme(ThemeMode.system);

      expect(container.read(themeProvider.notifier).isDarkMode, isFalse);
    });
  });

  // ── ThemeNotifier persistence ────────────────────────────────────────────────
  //
  // Persistence is tested by pre-populating SharedPreferences and verifying the
  // notifier loads the correct value on initialization. This avoids race
  // conditions from fire-and-forget saves that are not awaited by callers.

  group('ThemeNotifier — persistence', () {
    test('loads dark theme from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': ThemeMode.dark.index});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider); // trigger lazy initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('loads light theme from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': ThemeMode.light.index});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('loads system theme from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': ThemeMode.system.index});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(themeProvider), ThemeMode.system);
    });

    test('falls back to light when no theme stored', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('setDarkMode() updates SharedPreferences key', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier).setDarkMode();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);
    });

    test('setLightMode() updates SharedPreferences key', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeProvider.notifier).setDarkMode();
      container.read(themeProvider.notifier).setLightMode();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
    });
  });
}
