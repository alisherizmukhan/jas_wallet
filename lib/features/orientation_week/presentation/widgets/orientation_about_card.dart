import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import '../theme/orientation_brand.dart';


/// The "About Orientation Week" intro — a collapsible explainer on the
/// Overview. It says what Orientation Week is and what to expect (three
/// highlight rows). Like an FAQ row it folds to just its header when
/// collapsed and never disappears; the open/closed state is persisted
/// (`orientationAboutCollapsedProvider`).
class OrientationAboutCard extends StatelessWidget {
  const OrientationAboutCard({super.key, required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureHeaderCard(
      icon: AppIcons.sparkles,
      accent: OrientationBrand.accent,
      title: l10n.orientation_about_title,
      collapsed: collapsed,
      onToggle: onToggle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orientation_about_body,
            style: FeatureStyle.body.copyWith(color: FeatureStyle.bodyInk.withValues(alpha: 0.82), height: 1.4),
          ),
          const SizedBox(height: 14),
          _AboutPoint(
            icon: AppIcons.location,
            accent: OrientationBrand.accentTeal,
            title: l10n.orientation_about_point_explore_title,
            body: l10n.orientation_about_point_explore_body,
          ),
          const SizedBox(height: 10),
          _AboutPoint(
            icon: AppIcons.users,
            accent: OrientationBrand.accentPink,
            title: l10n.orientation_about_point_connect_title,
            body: l10n.orientation_about_point_connect_body,
          ),
          const SizedBox(height: 10),
          _AboutPoint(
            icon: AppIcons.trophy,
            accent: OrientationBrand.accentOrange,
            title: l10n.orientation_about_point_earn_title,
            body: l10n.orientation_about_point_earn_body,
          ),
        ],
      ),
    );
  }
}

class _AboutPoint extends StatelessWidget {
  const _AboutPoint({required this.icon, required this.accent, required this.title, required this.body});

  final AppIconData icon;
  final Color accent;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: FeatureStyle.chipTint(accent),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: AppIcon(icon, size: 15, color: accent)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FeatureStyle.caption.copyWith(color: FeatureStyle.ink, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 1),
              Text(body, style: FeatureStyle.tiny.copyWith(fontWeight: FontWeight.w400, color: FeatureStyle.mute, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
