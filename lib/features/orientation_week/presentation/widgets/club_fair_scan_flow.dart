import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../data/repositories/orientation_tasks_remote.dart';
import '../pages/bingo_qr_scan_page.dart';
import '../providers/orientation_bingo_provider.dart';
import '../providers/orientation_challenges_provider.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../providers/orientation_leaderboard_provider.dart';
import '../providers/orientation_repository_provider.dart';
import 'orientation_confetti.dart';

Future<void> openClubFairScan(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final code = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => BingoQrScanPage(tileTitle: l10n.orientation_club_scan_cta),
    ),
  );
  if (!context.mounted || code == null || code.isEmpty) return;

  try {
    final result = await ref.read(orientationRepositoryProvider).scanClubQr(code);
    if (!context.mounted) return;

    ref.read(orientationDashboardProvider.notifier).load();
    ref.read(orientationBingoProvider.notifier).load();
    ref.read(orientationChallengesProvider.notifier).load();
    ref.read(orientationLeaderboardProvider.notifier).load();

    if (result.alreadyCompleted) {
      AppToast.showInfo(context, l10n.orientation_club_scan_already);
      return;
    }

    if (result.totalTokens > 0) {
      RewardToastManager.showReward(
        context,
        RewardItem(
          title: result.clubName,
          tokenAmount: result.totalTokens,
          icon: AppIcons.qrCode,
          tokenIcon: AppIcons.tokenAdsl,
        ),
      );
    }

    if (result.bingoLineTokens > 0 || result.bingoGrandTokens > 0) {
      OrientationConfetti.play(context);
    }
  } on OrientationTaskRejected catch (e) {
    if (!context.mounted) return;
    AppToast.showError(context, _scanMessage(l10n, e.detail));
  } catch (_) {
    if (!context.mounted) return;
    AppToast.showError(context, l10n.orientation_bingo_scan_failed);
  }
}

String _scanMessage(AppLocalizations l10n, String detail) {
  return switch (detail) {
    'club_already_completed' => l10n.orientation_club_scan_already,
    'wrong_club_qr' => l10n.orientation_club_scan_wrong,
    'club_qr_expired' => l10n.orientation_club_scan_expired,
    'cannot_scan_own_club' => l10n.orientation_club_scan_own,
    'club_qr_outside_window' => l10n.orientation_club_scan_outside,
    'club_fair_closed' => l10n.orientation_club_scan_closed,
    'no_connection' => l10n.profile_errorNetwork,
    _ => l10n.orientation_bingo_scan_failed,
  };
}
