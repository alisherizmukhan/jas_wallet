import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'feature_style.dart';

/// The app-bar balance capsule — the token.svg glyph (never tinted) plus the
/// grouped balance.
///
/// Shared by Orientation Week and Club Fair: the two features keep separate
/// balances, but a student must never have to work out which pill they are
/// looking at from its shape.
class FeatureTokenPill extends StatelessWidget {
  const FeatureTokenPill({super.key, required this.amount, this.semanticsLabel, this.accent, this.icon});

  final int amount;

  /// Screen-reader label. Passed in rather than read from `AppLocalizations`
  /// so this stays in `app_ui`, which has no dependency on the app's ARB.
  final String? semanticsLabel;

  /// Overrides the shared [FeatureStyle.accent] capsule fill — null keeps
  /// the default (used by every caller that doesn't opt in, e.g. Club Fair).
  final Color? accent;

  /// Overrides the glyph — null keeps [AppIcons.token], the shared campus
  /// mark every caller that doesn't opt in (e.g. Club Fair) still uses.
  final AppIconData? icon;

  /// 2140 → "2,140". Done locally rather than via `intl` so the separator
  /// stays a comma regardless of the active locale, matching the design.
  static String grouped(int amount) {
    final s = amount.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    // The balance capsule uses the same cobalt-fill "emphasis" language as
    // every selected tab/chip elsewhere in the feature — one accent, reused.
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent ?? FeatureStyle.accent,
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon ?? AppIcons.token, size: 16),
            const SizedBox(width: 6),
            Text(
              grouped(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FeatureStyle.onDark,
                letterSpacing: -0.2,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
