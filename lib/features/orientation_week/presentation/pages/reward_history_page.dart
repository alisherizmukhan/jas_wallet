import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/reward.dart';
import '../providers/orientation_rewards_provider.dart';
import '../widgets/redemption_detail_sheet.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/reward_visuals.dart';
import '../theme/orientation_brand.dart';

String _grouped(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Redemption history — a summary of what's been claimed, then a card per
/// redemption with its date, tokens spent and collection status.
///
/// Tapping a card opens who redeemed it. Prizes are handed over after a check
/// by a person rather than against a pickup code, so the card no longer shows
/// one: the student's name, ID and email are what the desk actually asks for,
/// and those live one tap in.
class RewardHistoryPage extends ConsumerWidget {
  const RewardHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(orientationRewardHistoryProvider);
    final user = ref.watch(userProvider).valueOrNull;

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_rw_history_title, showTokens: true),
      body: SafeArea(
        child: history.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 20), child: OrientationDashboardSkeleton()),
          error: (_, _) => OrientationErrorState(onRetry: () => ref.invalidate(orientationRewardHistoryProvider)),
          data: (entries) {
            if (entries.isEmpty) return _Empty(label: l10n.orientation_rw_history_empty);

            final totalSpent = entries.fold<int>(0, (sum, e) => sum + e.spentTokens);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                FeatureFadeIn(child: _SummaryCard(count: entries.length, totalSpent: totalSpent)),
                const SizedBox(height: 16),
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  FeatureFadeIn(
                    delay: Duration(milliseconds: 40 * (i + 1)),
                    child: _HistoryCard(
                      entry: entries[i],
                      onTap: () => showRedemptionDetailSheet(
                        context,
                        entry: entries[i],
                        studentName: user?.fullName,
                        studentId: user?.studentId,
                        studentEmail: user?.email,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count, required this.totalSpent});

  final int count;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: FeatureStyle.chipTint(OrientationBrand.accent), borderRadius: BorderRadius.circular(FeatureStyle.rChip)),
            child: Center(child: AppIcon(AppIcons.gift, size: 24, color: OrientationBrand.accent)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.orientation_rw_total_spent, style: FeatureStyle.caption.copyWith(color: FeatureStyle.stone, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Token artwork keeps its own colours — never tinted.
                    const AppIcon(AppIcons.tokenAdsl, size: 19),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _grouped(totalSpent),
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: OrientationBrand.accent, letterSpacing: -0.3),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: FeatureStyle.chipTint(OrientationBrand.accent), borderRadius: BorderRadius.circular(FeatureStyle.rPill)),
            child: Text(
              l10n.orientation_rw_redeemed_count(count),
              style: FeatureStyle.caption.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.onTap});

  final RewardRedemption entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = RewardVisuals.tint(entry.reward.image);

    return FeatureCard(
      onTap: onTap,
      padding: const EdgeInsets.all(FeatureStyle.s16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(RewardVisuals.photo(entry.reward), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.reward.title, style: FeatureStyle.cardTitle.copyWith(fontSize: 14), maxLines: 1),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        AppIcon(AppIcons.time, size: 12, color: FeatureStyle.stone),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _formatDate(context, entry.redeemedAt),
                            style: FeatureStyle.tiny.copyWith(color: FeatureStyle.stone, fontWeight: FontWeight.w400),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token artwork keeps its own colours — never tinted.
                  const AppIcon(AppIcons.tokenAdsl, size: 14),
                  const SizedBox(width: 3),
                  Text('−${_grouped(entry.spentTokens)}',
                      style: FeatureStyle.caption.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(
                collected: entry.isCollected,
                collectedLabel: l10n.orientation_rw_collected,
                pendingLabel: l10n.orientation_rw_to_collect,
              ),
              const Spacer(),
              // Where the pickup code used to be. The code is gone because
              // nobody reads one off a phone any more — a person checks the
              // student instead — so the card points at who redeemed it.
              Text(
                l10n.orientation_rw_view_details,
                style: FeatureStyle.tiny.copyWith(
                  color: OrientationBrand.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              AppIcon(AppIcons.chevronRight, size: 14, color: OrientationBrand.accent),
            ],
          ),
        ],
      ),
    );
  }

  /// Localised via `intl` rather than a hardcoded English month table, so a
  /// Russian or Kazakh student sees a date in their own language.
  static String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${DateFormat.yMMMd(locale).format(date)}, ${DateFormat.Hm(locale).format(date)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.collected, required this.collectedLabel, required this.pendingLabel});

  final bool collected;
  final String collectedLabel;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    final color = collected ? AppColors.success : AppColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(collected ? AppIcons.checkCircle : AppIcons.time, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            collected ? collectedLabel : pendingLabel,
            style: FeatureStyle.tiny.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: OrientationBrand.accent.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Center(child: AppIcon(AppIcons.gift, size: 32, color: OrientationBrand.accent)),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
