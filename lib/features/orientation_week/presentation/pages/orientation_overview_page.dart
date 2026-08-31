import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/routing/app_router.dart';
import '../providers/orientation_about_provider.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../widgets/club_fair_schedule_card.dart';
import '../widgets/club_scan_home_card.dart';
import '../widgets/orientation_about_card.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_faq_section.dart';
import '../widgets/orientation_offline_state.dart';
import '../widgets/orientation_partner_card.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/overall_progress_card.dart';
import '../theme/orientation_brand.dart';

/// Club Fair Home — partner, about, quest progress, club scan, booth schedule,
/// student leaderboard, club ranking CTA, FAQ. One network call: `GET /club-fair/home`.
class OrientationOverviewPage extends ConsumerStatefulWidget {
  const OrientationOverviewPage({super.key});

  @override
  ConsumerState<OrientationOverviewPage> createState() => _OrientationOverviewPageState();
}

class _OrientationOverviewPageState extends ConsumerState<OrientationOverviewPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackOrientationOpened();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationDashboardProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(
        title: l10n.orientation_week_title,
        isShellRoot: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationDashboardProvider.notifier).load(),
          child: _buildBody(context, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, OrientationDashboardState state) {
    if (state.isLoading && !state.hasData) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(padding: EdgeInsets.only(top: 20), child: OrientationDashboardSkeleton()),
      );
    }
    if (state.isOffline && !state.hasData) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationOfflineState(onRetry: () => ref.read(orientationDashboardProvider.notifier).load()),
      );
    }
    if (state.error != null && !state.hasData) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(onRetry: () => ref.read(orientationDashboardProvider.notifier).load()),
      );
    }

    final dashboard = state.dashboard;
    if (dashboard == null) return const SizedBox.shrink();

    final aboutCollapsed = ref.watch(orientationAboutCollapsedProvider);
    const stagger = Duration(milliseconds: 45);

    return FeaturePageBody(
      children: [
        const FeatureFadeIn(child: OrientationPartnerCard()),
        FeatureFadeIn(
          delay: stagger,
          child: OrientationAboutCard(
            collapsed: aboutCollapsed,
            onToggle: () => ref.read(orientationAboutCollapsedProvider.notifier).toggle(),
          ),
        ),
        FeatureFadeIn(
          delay: stagger * 2,
          child: OverallProgressCard(
            completed: dashboard.questCompleted,
            total: dashboard.questTotal,
          ),
        ),
        FeatureFadeIn(
          delay: stagger * 3,
          child: ClubScanHomeCard(dashboard: dashboard),
        ),
        FeatureFadeIn(
          delay: stagger * 4,
          child: ClubFairScheduleCard(slots: dashboard.slots),
        ),
        FeatureFadeIn(
          delay: stagger * 5,
          child: _LeaderboardCta(l10n: l10n, rank: dashboard.rank),
        ),
        FeatureFadeIn(
          delay: stagger * 6,
          child: const _ClubRankingCta(),
        ),
        const FeatureFadeIn(
          delay: Duration(milliseconds: 360),
          child: OrientationFaqSection(),
        ),
      ],
    );
  }
}

class _LeaderboardCta extends StatelessWidget {
  const _LeaderboardCta({required this.l10n, required this.rank});

  final AppLocalizations l10n;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      child: FeatureListRow(
        icon: AppIcons.trophy,
        iconColor: OrientationBrand.accent,
        title: l10n.orientation_view_leaderboard,
        subtitle: l10n.orientation_leaderboard_cta_subtitle,
        trailing: rank > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FeatureStyle.chipTint(OrientationBrand.accent),
                  borderRadius: BorderRadius.circular(FeatureStyle.rPill),
                ),
                child: Text(
                  '#$rank',
                  style: FeatureStyle.caption.copyWith(
                    color: OrientationBrand.accent,
                    fontWeight: FontWeight.w700,
                    fontFeatures: FeatureStyle.tabular,
                  ),
                ),
              )
            : null,
        onTap: () => context.push(AppRoutes.orientationLeaderboard),
      ),
    );
  }
}

class _ClubRankingCta extends StatelessWidget {
  const _ClubRankingCta();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureCard(
      child: FeatureListRow(
        icon: AppIcons.leaderboard,
        iconColor: OrientationBrand.accent,
        title: l10n.orientation_club_ranking_cta,
        subtitle: l10n.orientation_club_ranking_cta_subtitle,
        onTap: () => context.push(AppRoutes.orientationClubRanking),
      ),
    );
  }
}
