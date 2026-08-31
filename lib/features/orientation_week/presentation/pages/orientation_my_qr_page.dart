import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_identity.dart';
import '../providers/orientation_identity_provider.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_qr_card.dart';
import '../theme/orientation_brand.dart';

/// The student's own Orientation code.
///
/// Two students complete a peer-scan challenge by one of them opening this and
/// the other scanning it, so this page is half of every QR task — which is why
/// it is reachable from the Challenges tab rather than buried in a profile.
///
/// The school baked into the code is resolved automatically from the SALTO
/// directory — there is nothing here for the student to set or change, only
/// a state to wait out (or retry, if it genuinely comes back empty).
class OrientationMyQrPage extends ConsumerWidget {
  const OrientationMyQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final identity = ref.watch(orientationIdentityProvider);
    final schoolState = ref.watch(orientationSchoolProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_my_qr, showTokens: false),
      body: SafeArea(
        child: FeaturePageBody(
          children: [
            if (identity != null) ...[
              FeatureFadeIn(child: OrientationQrCard(identity: identity)),
              FeatureFadeIn(
                delay: const Duration(milliseconds: 45),
                child: Text(
                  l10n.orientation_my_qr_body,
                  textAlign: TextAlign.center,
                  style: FeatureStyle.secondary,
                ),
              ),
              FeatureFadeIn(
                delay: const Duration(milliseconds: 90),
                child: FeatureCard(
                  child: FeatureListRow(
                    icon: AppIcons.school,
                    iconColor: OrientationBrand.accent,
                    title: identity.school.code,
                    subtitle: identity.school.label,
                    showChevron: false,
                  ),
                ),
              ),
            ] else
              // A resolved-but-empty school (or a lookup error) is the only
              // state worth telling the student apart from "still loading" —
              // everything else (school pending, or resolved but the profile
              // itself hasn't landed yet) reads the same: wait a moment.
              FeatureFadeIn(
                child: schoolState.maybeWhen(
                  data: (school) => school == null
                      ? _SchoolStatusCard(
                          icon: AppIcons.warning,
                          title: l10n.orientation_school_unresolved_title,
                          body: l10n.orientation_school_unresolved_body,
                          onRetry: () => ref.read(orientationSchoolProvider.notifier).load(),
                        )
                      : const _SchoolPendingCard(),
                  error: (_, _) => _SchoolStatusCard(
                    icon: AppIcons.warning,
                    title: l10n.orientation_school_unresolved_title,
                    body: l10n.orientation_school_unresolved_body,
                    onRetry: () => ref.read(orientationSchoolProvider.notifier).load(),
                  ),
                  orElse: () => const _SchoolPendingCard(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SchoolPendingCard extends StatelessWidget {
  const _SchoolPendingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s24),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: OrientationBrand.accent),
          ),
          const SizedBox(height: FeatureStyle.s16),
          Text(l10n.orientation_school_pending, textAlign: TextAlign.center, style: FeatureStyle.cardTitle),
          const SizedBox(height: FeatureStyle.s4),
          Text(
            l10n.orientation_school_pending_body,
            textAlign: TextAlign.center,
            style: FeatureStyle.secondary,
          ),
        ],
      ),
    );
  }
}

class _SchoolStatusCard extends StatelessWidget {
  const _SchoolStatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final AppIconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: FeatureStyle.surfaceSoft, shape: BoxShape.circle),
            child: AppIcon(icon, size: 28, color: FeatureStyle.stone),
          ),
          const SizedBox(height: FeatureStyle.s16),
          Text(title, textAlign: TextAlign.center, style: FeatureStyle.cardTitle),
          const SizedBox(height: FeatureStyle.s4),
          Text(body, textAlign: TextAlign.center, style: FeatureStyle.secondary),
          if (onRetry != null) ...[
            const SizedBox(height: FeatureStyle.s20),
            FeatureCtaButton(accent: OrientationBrand.accent, label: l10n.orientation_school_retry, icon: AppIcons.refresh, onTap: onRetry!),
          ],
        ],
      ),
    );
  }
}
