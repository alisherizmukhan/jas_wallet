import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../theme/orientation_brand.dart';
import 'club_fair_scan_flow.dart';

/// Home / Tasks CTA to scan a stand QR, with scan counts from [GET /club-fair/home].
///
/// Listed club reps also get a second button that opens the rotating stand QR.
class ClubScanHomeCard extends ConsumerWidget {
  const ClubScanHomeCard({super.key, required this.dashboard});

  final OrientationDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scanned = dashboard.clubsScanned;
    final total = dashboard.clubsTotal;
    final fraction = total == 0 ? 0.0 : (scanned / total).clamp(0.0, 1.0);

    return FeatureCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dashboard.isRep) ...[
            FeatureCtaButton(
              accent: OrientationBrand.accent,
              style: FeatureCtaStyle.outlined,
              label: l10n.orientation_club_stand_qr_cta,
              icon: AppIcons.qrCode,
              onTap: () => context.push(AppRoutes.orientationClubStandQr),
            ),
            const SizedBox(height: 12),
          ],
          FeatureCtaButton(
            accent: OrientationBrand.accent,
            label: l10n.orientation_club_scan_cta,
            icon: AppIcons.qrCode,
            onTap: () => openClubFairScan(context, ref),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.orientation_club_scan_progress(scanned, total),
            style: FeatureStyle.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            progress: fraction,
            height: 7,
            progressColor: OrientationBrand.accent,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orientation_club_scan_tokens(dashboard.clubScanTokens),
            style: FeatureStyle.caption.copyWith(color: FeatureStyle.mute),
          ),
        ],
      ),
    );
  }
}
