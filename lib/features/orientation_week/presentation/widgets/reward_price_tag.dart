import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import '../theme/orientation_brand.dart';

/// A token price — the never-recoloured token SVG beside the amount. Used on
/// cards (with the "tokens" suffix) and in dense rows (amount only).
class RewardPriceTag extends StatelessWidget {
  const RewardPriceTag({
    super.key,
    required this.tokens,
    this.showSuffix = false,
    this.iconSize = 16,
    this.fontSize = 14,
  });

  final int tokens;
  final bool showSuffix;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatted = _grouped(tokens);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Token artwork keeps its own colours — never tinted.
        AppIcon(AppIcons.tokenAdsl, size: iconSize),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              showSuffix ? l10n.orientation_rw_tokens_suffix(formatted) : formatted,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: OrientationBrand.accent,
                letterSpacing: -0.2,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 5000 → "5,000". Kept local so the price tag needs no intl dependency.
  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Formats a token count with thousands separators for use in plain text.
String formatTokens(int value) => RewardPriceTag._grouped(value);
