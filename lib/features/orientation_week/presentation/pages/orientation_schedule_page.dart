import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../providers/orientation_dashboard_provider.dart';
import '../widgets/club_fair_schedule_card.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_error_state.dart';

/// Full Club Fair booth list — same slot UI as Home, no extra GET.
class OrientationSchedulePage extends ConsumerWidget {
  const OrientationSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationDashboardProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_schedule),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationDashboardProvider.notifier).load(),
          child: state.dashboard == null && state.error != null
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: OrientationErrorState(
                    onRetry: () => ref.read(orientationDashboardProvider.notifier).load(),
                  ),
                )
              : FeaturePageBody(
                  children: [
                    ClubFairScheduleCard(slots: state.dashboard?.slots ?? const []),
                  ],
                ),
        ),
      ),
    );
  }
}
