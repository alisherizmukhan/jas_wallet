import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../providers/orientation_leaderboard_provider.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_preview.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/your_position_card.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackOrientationLeaderboardOpened();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationLeaderboardProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_leaderboard, showTokens: true),
      // Global ranking only — no scope selector.
      body: SafeArea(
        child: _buildBody(context, l10n, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, OrientationLeaderboardState state) {
    if (state.isLoading && state.entries.isEmpty) {
      return const OrientationDashboardSkeleton();
    }
    if (state.error != null && state.entries.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(onRetry: () => ref.read(orientationLeaderboardProvider.notifier).load()),
      );
    }

    final entries = state.entries;
    final hasPodium = entries.length >= 3;
    final topThree = entries.take(3).toList();
    // Podium covers ranks 1–3; the list then fills up to rank 10.
    final listStart = hasPodium ? 3 : 0;
    final topRows = entries.skip(listStart).take(10 - listStart).toList();

    final currentUserIndex = entries.indexWhere((e) => e.isCurrentUser);
    final currentUserEntry = currentUserIndex == -1 ? null : entries[currentUserIndex];
    final userInTop10 = currentUserIndex != -1 && currentUserIndex < 10;
    final entryAbove = currentUserIndex > 0 ? entries[currentUserIndex - 1] : null;

    return RefreshIndicator(
      onRefresh: () => ref.read(orientationLeaderboardProvider.notifier).load(),
      child: FeaturePageBody(
        children: [
          if (hasPodium)
            LeaderboardPodium(topThree: topThree),
          if (topRows.isNotEmpty)
            FeatureSection(
              title: l10n.orientation_leaderboard_rankings,
              // The list and the out-of-top-10 tail belong to one section:
              // the rank gap only makes sense as a continuation of the rows
              // above it, so the standard section gap must not fall between
              // them.
              child: Column(
                children: [
                  LeaderboardPreview(entries: topRows),
                  // When the student is outside the top 10, pin their own
                  // position as an 11th entry below the list, with a gap
                  // showing the skipped ranks.
                  if (currentUserEntry != null && !userInTop10) ...[
                    const SizedBox(height: FeatureStyle.s12),
                    const _RankGap(),
                    const SizedBox(height: FeatureStyle.s12),
                    YourPositionCard(entry: currentUserEntry, entryAbove: entryAbove),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Three muted dots signalling the ranks skipped between the top 10 and the
/// current student's own (lower) position.
class _RankGap extends StatelessWidget {
  const _RankGap();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: FeatureStyle.stone.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
