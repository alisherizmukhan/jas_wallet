import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icons.dart';
import 'feature_style.dart';

/// A token price — the never-recoloured token SVG beside the amount.
///
/// Used on cards (with a "tokens" suffix supplied by the caller) and in dense
/// rows (amount only). The suffix is a parameter rather than an l10n lookup so
/// this can live in `app_ui`, which has no access to the app's ARB.
class FeaturePriceTag extends StatelessWidget {
  const FeaturePriceTag({
    super.key,
    required this.tokens,
    this.suffixBuilder,
    this.iconSize = 16,
    this.fontSize = 14,
    this.color = FeatureStyle.accent,
  });

  final int tokens;

  /// Given the grouped amount ("5,000"), returns the full label
  /// ("5,000 tokens"). Null renders the amount alone.
  final String Function(String grouped)? suffixBuilder;

  final double iconSize;
  final double fontSize;

  /// Dimmed to [FeatureStyle.stone] where a price is out of reach.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatted = formatTokens(tokens);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Token artwork keeps its own colours — never tinted.
        AppIcon(AppIcons.token, size: iconSize),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              suffixBuilder?.call(formatted) ?? formatted,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 5000 → "5,000". Kept local so the price tag needs no intl dependency, and
/// so the separator stays a comma regardless of the active locale.
String formatTokens(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
