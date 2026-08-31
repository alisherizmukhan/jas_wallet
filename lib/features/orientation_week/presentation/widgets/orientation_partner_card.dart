import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../providers/orientation_partner_provider.dart';
import '../theme/orientation_brand.dart';

/// The partner credit on the Overview — Orientation Week runs in collaboration
/// with ADSL, and this is where that is stated.
///
/// Folds open like an FAQ row (state persisted) to a short "what is ADSL"
/// blurb, with a separate row to jump to their Instagram — the same profile
/// the follow task on Challenges points at. Since a [FeatureHeaderCard]
/// either unfolds or navigates, the header's tap toggles the blurb and the
/// Instagram hop lives inside it as its own tappable row.
class OrientationPartnerCard extends StatelessWidget {
  const OrientationPartnerCard({super.key});

  static const String _logoAsset = 'assets/adsl.jpeg';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context)!;
        final collapsed = ref.watch(orientationPartnerCollapsedProvider);

        return FeatureHeaderCard(
          // The one card that is literally about ADSL gets their own
          // neutral, not the feature's flat card fill — cream in light mode,
          // their near-black in dark mode, the same surface/text swap the
          // rest of the theme does with its own neutrals.
          backgroundColor: FeatureStyle.isDark ? OrientationBrand.ink : OrientationBrand.cream,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(FeatureStyle.rChip),
            child: Image.asset(
              _logoAsset,
              width: FeatureHeaderCard.chipSize,
              height: FeatureHeaderCard.chipSize,
              fit: BoxFit.cover,
              // The credit still reads without the mark; a missing asset must
              // not take the card down with it.
              errorBuilder: (_, _, _) => const SizedBox(
                width: FeatureHeaderCard.chipSize,
                height: FeatureHeaderCard.chipSize,
              ),
            ),
          ),
          title: l10n.orientation_partner_title,
          collapsed: collapsed,
          onToggle: () => ref.read(orientationPartnerCollapsedProvider.notifier).toggle(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.orientation_partner_body,
                style: FeatureStyle.body.copyWith(color: FeatureStyle.bodyInk.withValues(alpha: 0.82), height: 1.4),
              ),
              const SizedBox(height: 14),
              _InstagramButton(
                label: l10n.orientation_partner_instagram_cta,
                onTap: () => openOrientationLink(OrientationLinks.adslInstagram),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The same Instagram-gradient pill used for the follow CTAs on the Contest
/// page — a real button, not a plain tappable row, so the one external hop
/// this card offers reads as an action rather than a footnote.
class _InstagramButton extends StatelessWidget {
  const _InstagramButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const _igStart = Color(0xFFF58529);
  static const _igMid = Color(0xFFDD2A7B);
  static const _igEnd = Color(0xFF8134AF);

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FeatureStyle.rChip),
          gradient: const LinearGradient(
            colors: [_igStart, _igMid, _igEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(color: _igMid.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(AppIcons.instagram, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
