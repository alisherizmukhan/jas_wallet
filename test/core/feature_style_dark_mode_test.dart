import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FeatureStyle's neutrals resolve dynamically off an ambient brightness
/// flag (see lib/main.dart's MaterialApp builder for how it's kept live) —
/// this just checks the getters themselves branch correctly.
void main() {
  tearDown(() => FeatureStyle.updateBrightness(Brightness.light));

  test('neutrals resolve to light values by default', () {
    expect(FeatureStyle.isDark, isFalse);
    expect(FeatureStyle.ink, const Color(0xFF191C1F));
    expect(FeatureStyle.pageBackground, AppColors.white);
    expect(FeatureStyle.hairline, const Color(0xFFE2E2E7));
  });

  test('neutrals resolve to dark values after updateBrightness(dark)', () {
    FeatureStyle.updateBrightness(Brightness.dark);

    expect(FeatureStyle.isDark, isTrue);
    expect(FeatureStyle.ink, const Color(0xFFF5F5F5));
    expect(FeatureStyle.pageBackground, const Color(0xFF171717));
    expect(FeatureStyle.hairline, const Color(0xFF333333));
  });

  test('brand accents stay fixed across both themes', () {
    final lightAccent = FeatureStyle.accent;
    FeatureStyle.updateBrightness(Brightness.dark);
    expect(FeatureStyle.accent, lightAccent);
    expect(FeatureStyle.accentTeal, const Color(0xFF00A87E));
  });
}
