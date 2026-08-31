import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/club_fair_club_rank.dart';
import '../providers/club_fair_club_ranking_provider.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_skeletons.dart';

/// Global ranking of quest clubs by unique student scans.
class ClubFairClubRankingPage extends ConsumerWidget {
  const ClubFairClubRankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(clubFairClubRankingProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_club_ranking_title, showTokens: false),
      body: SafeArea(child: _body(context, ref, l10n, state)),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ClubFairClubRankingState state,
  ) {
    if (state.isLoading && !state.hasData) {
      return const OrientationDashboardSkeleton();
    }
    if (state.error != null && !state.hasData) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(
          onRetry: () => ref.read(clubFairClubRankingProvider.notifier).load(),
        ),
      );
    }
    final ranking = state.ranking;
    if (ranking == null) return const SizedBox.shrink();

    final clubs = ranking.clubs;
    final hasPodium = clubs.length >= 3 && clubs[2].scans > 0;
    final listStart = hasPodium ? 3 : 0;

    return RefreshIndicator(
      onRefresh: () => ref.read(clubFairClubRankingProvider.notifier).load(),
      child: FeaturePageBody(
        children: [
          FeatureFadeIn(
            child: Text(
              l10n.orientation_club_ranking_total(ranking.totalScans, clubs.length),
              style: FeatureStyle.secondary,
            ),
          ),
          if (hasPodium)
            FeatureFadeIn(
              delay: const Duration(milliseconds: 45),
              child: _ClubPodium(topThree: clubs.take(3).toList()),
            ),
          if (clubs.length > listStart)
            FeatureFadeIn(
              delay: const Duration(milliseconds: 90),
              child: FeatureSection(
                title: l10n.orientation_club_ranking_list,
                child: FeatureCard(
                  padding: const EdgeInsets.symmetric(vertical: FeatureStyle.s4),
                  child: Column(
                    children: [
                      for (final club in clubs.skip(listStart))
                        _ClubRankRow(club: club),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClubPodium extends StatelessWidget {
  const _ClubPodium({required this.topThree});

  final List<ClubFairClubRank> topThree;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumPlace(club: topThree[1], height: 72)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumPlace(club: topThree[0], height: 96, crowned: true)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumPlace(club: topThree[2], height: 56)),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.club,
    required this.height,
    this.crowned = false,
  });

  final ClubFairClubRank club;
  final double height;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final medal = switch (club.rank) {
      1 => const Color(0xFFF5B301),
      2 => const Color(0xFFB8C0CC),
      3 => const Color(0xFFCD9B6A),
      _ => FeatureStyle.stone,
    };

    return Column(
      children: [
        if (crowned)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: AppIcon(AppIcons.crown, size: 18, color: Color(0xFFF5B301)),
          )
        else
          const SizedBox(height: 22),
        Text(
          club.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FeatureStyle.caption.copyWith(
            color: FeatureStyle.ink,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: FeatureStyle.chipTint(medal),
            borderRadius: BorderRadius.circular(FeatureStyle.rCard),
            border: Border.all(color: medal.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${club.rank}',
                style: FeatureStyle.cardTitle.copyWith(
                  color: medal,
                  fontWeight: FontWeight.w800,
                  fontFeatures: FeatureStyle.tabular,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.orientation_club_ranking_scans(club.scans),
                style: FeatureStyle.tiny.copyWith(
                  color: FeatureStyle.mute,
                  fontWeight: FontWeight.w600,
                  fontFeatures: FeatureStyle.tabular,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubRankRow extends StatelessWidget {
  const _ClubRankRow({required this.club});

  final ClubFairClubRank club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final medal = switch (club.rank) {
      1 => AppColors.gold,
      2 => const Color(0xFFB8C0CC),
      3 => const Color(0xFFCD9B6A),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${club.rank}',
              style: FeatureStyle.cardTitle.copyWith(
                color: medal ?? FeatureStyle.stone,
                fontWeight: FontWeight.w800,
                fontFeatures: FeatureStyle.tabular,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FeatureStyle.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _slotLabel(l10n, locale, club),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FeatureStyle.tiny.copyWith(color: FeatureStyle.mute),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.orientation_club_ranking_scans(club.scans),
            style: FeatureStyle.cardTitle.copyWith(
              fontSize: 14,
              letterSpacing: -0.2,
              fontFeatures: FeatureStyle.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

String _slotLabel(AppLocalizations l10n, String locale, ClubFairClubRank club) {
  final slot = switch (club.slot) {
    'morning' => l10n.orientation_schedule_morning,
    'afternoon' => l10n.orientation_schedule_afternoon,
    'always' => l10n.orientation_schedule_always,
    _ => club.slot,
  };
  final day = club.standDate;
  if (day == null) return slot;
  return '${DateFormat.MMMd(locale).format(day.toLocal())} · $slot';
}
