import 'package:flutter/material.dart';

import '../icons/app_icon.dart';
import '../icons/app_icon_data.dart';
import 'feature_components.dart';
import 'feature_style.dart';

/// "Nothing here yet" — a glyph, a headline, a line of explanation, and
/// optionally the one action that would fix it.
///
/// Shared so an empty filter on Club Fair's Clubs tab and an empty filter on
/// Photo Quest are the same object rather than two designers' guesses.
class FeatureEmptyState extends StatelessWidget {
  const FeatureEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppIconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: FeatureStyle.s32,
        horizontal: FeatureStyle.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FeatureStyle.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: AppIcon(icon, size: 26, color: FeatureStyle.stone),
          ),
          const SizedBox(height: FeatureStyle.s16),
          Text(title, style: FeatureStyle.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: FeatureStyle.s4),
          Text(message, style: FeatureStyle.secondary, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: FeatureStyle.s20),
            FeatureCtaButton(
              label: actionLabel!,
              onTap: onAction!,
              style: FeatureCtaStyle.outlined,
            ),
          ],
        ],
      ),
    );
  }
}
