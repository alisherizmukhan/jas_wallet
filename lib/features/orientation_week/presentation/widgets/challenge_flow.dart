import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../config/orientation_links.dart';
import '../../data/models/orientation_task_api_mapper.dart';
import '../../data/repositories/orientation_tasks_remote.dart';
import '../../domain/entities/orientation_challenge.dart';
import '../providers/orientation_bingo_provider.dart';
import '../providers/orientation_challenges_provider.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../providers/orientation_identity_provider.dart';
import '../providers/orientation_leaderboard_provider.dart';
import '../providers/orientation_photo_quests_provider.dart';
import 'challenge_answer_sheet.dart';

/// Runs the interaction a challenge's kind calls for — the answer sheet, the
/// QR scanner, the referral screen — and refreshes every surface a completion
/// touches (challenge list, bingo board, token pill, leaderboard).
///
/// Shared between the Challenges grid and the Bingo board: a bingo square is
/// the same server task seen from another tab, so tapping it must run the
/// same flow, not a parallel one.
Future<void> openChallengeFlow(
  BuildContext context,
  WidgetRef ref,
  OrientationChallenge challenge,
) async {
  final notifier = ref.read(orientationChallengesProvider.notifier);

  switch (challenge.kind) {
    case ChallengeKind.referral:
      // No answer to store: the referral screen owns the whole job, and the
      // challenge credits itself once the friend actually signs up.
      context.push(AppRoutes.referral);

    case ChallengeKind.link:
    case ChallengeKind.telegramBot:
      // Telegram bot deep-link is injected by the API as `config.link`.
      // Membership / clawback are entirely server-side after Start.
      final link = challenge.link;
      if (link != null) await openOrientationLink(link);
      if (context.mounted) _refreshAfterCompletion(ref);

    case ChallengeKind.qrScan:
      if (challenge.rule != null && ref.read(orientationIdentityProvider) == null) {
        final l10n = AppLocalizations.of(context)!;
        AppToast.showError(context, l10n.orientation_school_scan_blocked);
        return;
      }
      await context.push(AppRoutes.orientationChallengeScanFor(challenge.id));
      if (context.mounted) _refreshAfterCompletion(ref);

    case ChallengeKind.text:
    case ChallengeKind.name:
    case ChallengeKind.handle:
      final choice = await showChallengeAnswerSheet(context, challenge);
      if (choice == null || !context.mounted) return;
      switch (choice) {
        case SaveChallengeAnswer(:final value):
          try {
            final awarded = await notifier.answer(challenge.id, value);
            if (!context.mounted) return;
            if (awarded > 0) {
              RewardToastManager.showReward(
                context,
                RewardItem(
                  title: challenge.title,
                  tokenAmount: awarded,
                  icon: AppIcons.check,
                  tokenIcon: AppIcons.tokenAdsl,
                ),
              );
            }
            _refreshAfterCompletion(ref);
          } on OrientationTaskRejected catch (e) {
            if (!context.mounted) return;
            AppToast.showError(context, _rejectionMessage(context, e));
          }
        case ClearChallengeAnswer():
          await notifier.clear(challenge.id);
      }

    case ChallengeKind.photo:
      final mission = photoMissionFromChallenge(challenge);
      ref.read(orientationPhotoQuestsProvider.notifier).upsert(mission);
      await context.push(AppRoutes.orientationPhotoQuestDetail, extra: mission);
      if (context.mounted) {
        await notifier.load();
        _refreshAfterCompletion(ref);
      }
  }
}

/// A completion moves tokens and can close a bingo cell or a whole line —
/// every derived surface reloads. Fire and forget: each provider owns its own
/// loading state.
void _refreshAfterCompletion(WidgetRef ref) {
  ref.read(orientationBingoProvider.notifier).load();
  ref.read(orientationDashboardProvider.notifier).load();
  ref.read(orientationLeaderboardProvider.notifier).load();
}

String _rejectionMessage(BuildContext context, OrientationTaskRejected e) {
  final l10n = AppLocalizations.of(context)!;
  return switch (e.detail) {
    'wrong_answer' => l10n.orientation_challenge_wrong_answer,
    'invalid_student_id' => l10n.orientation_challenge_invalid_student_id,
    'senior_not_found' => l10n.orientation_challenge_senior_not_found,
    'senior_too_recent' => l10n.orientation_challenge_senior_too_recent,
    'cannot_use_own_id' => l10n.orientation_challenge_own_student_id,
    'no_connection' => l10n.profile_errorNetwork,
    'club_fair_closed' => l10n.orientation_club_scan_closed,
    _ => l10n.profile_errorGeneric,
  };
}
