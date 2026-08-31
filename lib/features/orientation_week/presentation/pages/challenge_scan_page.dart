import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_identity.dart';
import '../providers/orientation_challenges_provider.dart';
import '../providers/orientation_identity_provider.dart';
import '../theme/orientation_brand.dart';

/// Scanning another student's Orientation code for a challenge.
///
/// Every rule is decided from the two QR payloads — no network — so this works
/// in a hall with no signal, which is exactly where it will be used.
///
/// The camera stops while an outcome is on screen and resumes when it is
/// dismissed, so a student holding the phone steady over one code cannot fire
/// the same scan a dozen times.
class ChallengeScanPage extends ConsumerStatefulWidget {
  const ChallengeScanPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<ChallengeScanPage> createState() => _ChallengeScanPageState();
}

class _ChallengeScanPageState extends ConsumerState<ChallengeScanPage> {
  ScanOutcome? _outcome;
  bool _busy = false;

  Future<void> _onDetect(String raw) async {
    if (_busy || _outcome != null) return;
    var me = ref.read(orientationIdentityProvider);
    me ??= const OrientationIdentity(
      studentId: 'venue',
      displayName: '',
      school: NuSchool.ssh,
    );

    setState(() => _busy = true);
    ScanOutcome? outcome;
    try {
      outcome = await ref.read(orientationChallengesProvider.notifier).submitScan(
            challengeId: widget.challengeId,
            me: me,
            scannedRaw: raw,
          );
    } catch (_) {
      // Server unreachable mid-scan: resume the camera instead of dying —
      // the student just points at the code again.
      if (mounted) {
        AppToast.showError(context, AppLocalizations.of(context)!.profile_errorNetwork);
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  void _dismiss() {
    // An accepted scan is the end of the job — close the scanner rather than
    // inviting a student to keep scanning a task they have finished.
    if (_outcome is ScanAccepted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _outcome = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final challenge = ref.watch(challengeByIdProvider(widget.challengeId));
    final outcome = _outcome;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AppQrScanner(
        active: outcome == null && !_busy,
        showViewfinder: outcome == null,
        title: challenge?.title ?? l10n.orientation_qr_scan_someone,
        instruction: challenge?.description,
        onDetect: _onDetect,
        onClose: () => context.pop(),
        overlay: outcome == null ? null : _OutcomeSheet(outcome: outcome, onDismiss: _dismiss),
      ),
    );
  }
}

/// The result, over the paused camera.
class _OutcomeSheet extends StatelessWidget {
  const _OutcomeSheet({required this.outcome, required this.onDismiss});

  final ScanOutcome outcome;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (icon, accent, title, body) = switch (outcome) {
      ScanUnrecognised() => (
          AppIcons.qrCode,
          FeatureStyle.stone,
          l10n.orientation_scan_not_ours,
          l10n.orientation_scan_not_ours_body,
        ),
      ScanSelf() => (
          AppIcons.info,
          OrientationBrand.accentOrange,
          l10n.orientation_scan_self,
          l10n.orientation_scan_self_body,
        ),
      ScanDuplicate(:final identity) => (
          AppIcons.history,
          OrientationBrand.accentOrange,
          l10n.orientation_scan_duplicate,
          l10n.orientation_scan_duplicate_body(identity.displayName),
        ),
      ScanRejected(:final identity, :final reason) => (
          AppIcons.warning,
          OrientationBrand.accentPink,
          identity.displayName,
          reason,
        ),
      // A venue poster (identity is a synthetic `venue:` stand-in) has no
      // student behind it — the confirmation shows only the payout.
      ScanAccepted(:final identity, :final awardedTokens)
          when identity.studentId.startsWith('venue:') =>
        (
          AppIcons.checkCircle,
          OrientationBrand.accentTeal,
          l10n.orientation_scan_accepted,
          awardedTokens > 0 ? '+$awardedTokens' : '',
        ),
      ScanAccepted(:final identity, :final awardedTokens) => (
          AppIcons.checkCircle,
          OrientationBrand.accentTeal,
          l10n.orientation_scan_accepted,
          awardedTokens > 0
              ? '${identity.displayName} · ${identity.school.code} · +$awardedTokens'
              : '${identity.displayName} · ${identity.school.code}',
        ),
    };

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.86),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(FeatureStyle.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(icon, size: 32, color: accent),
                ),
                const SizedBox(height: FeatureStyle.s20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: FeatureStyle.sectionTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: FeatureStyle.s8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: FeatureStyle.secondary.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: FeatureStyle.s32),
                SizedBox(
                  width: 220,
                  child: FeatureCtaButton(accent: OrientationBrand.accent, 
                    label: outcome is ScanAccepted
                        ? l10n.orientation_challenge_done
                        : l10n.common_retry,
                    onTap: onDismiss,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
