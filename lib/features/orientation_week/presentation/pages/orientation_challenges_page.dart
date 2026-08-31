import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/orientation_challenge.dart';
import '../providers/orientation_challenges_provider.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_flow.dart';
import '../widgets/club_scan_home_card.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_segmented_tabs.dart';
import '../theme/orientation_brand.dart';

const _knownGroupOrder = ['general', 'today', 'clubs', 'photo', 'qr'];

/// Club Fair tasks, filtered by a single row of type chips.
class OrientationChallengesPage extends ConsumerStatefulWidget {
  const OrientationChallengesPage({super.key});

  @override
  ConsumerState<OrientationChallengesPage> createState() =>
      _OrientationChallengesPageState();
}

class _OrientationChallengesPageState
    extends ConsumerState<OrientationChallengesPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationChallengesProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(
        title: l10n.orientation_tab_challenges,
        isShellRoot: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationChallengesProvider.notifier).load(),
          child: _body(context, state, l10n),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ChallengesState state,
    AppLocalizations l10n,
  ) {
    if (state.isLoading && !state.hasData) {
      return Center(child: CircularProgressIndicator(color: OrientationBrand.accent));
    }
    if (state.error != null && !state.hasData) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(
          onRetry: () => ref.read(orientationChallengesProvider.notifier).load(),
        ),
      );
    }

    final dashboard = ref.watch(orientationDashboardProvider).dashboard;
    final keys = _filterKeys(state.ordered);
    final selected = keys.contains(_filter) ? _filter : 'all';
    final shown = selected == 'all' || selected == 'clubs'
        ? state.ordered
        : state.ordered.where((c) => c.group == selected).toList();

    return FeaturePageBody(
      children: [
        OrientationSegmentedTabs(
          items: [
            for (final key in keys) OrientationTabItem(label: _groupLabel(l10n, key)),
          ],
          selectedIndex: keys.indexOf(selected),
          onChanged: (i) => setState(() => _filter = keys[i]),
        ),
        if ((selected == 'all' || selected == 'clubs') && dashboard != null)
          ClubScanHomeCard(dashboard: dashboard),
        if (selected != 'clubs')
          FeatureTwoColumnGrid(
            children: [
              for (final challenge in shown) _ChallengeCell(challenge: challenge),
            ],
          ),
      ],
    );
  }
}

List<String> _filterKeys(Iterable<OrientationChallenge> challenges) {
  final present = {for (final c in challenges) c.group};
  final keys = <String>['all'];
  for (final key in _knownGroupOrder) {
    if (key == 'clubs' || present.contains(key)) keys.add(key);
  }
  final extras = present
      .where((key) => key.isNotEmpty && !_knownGroupOrder.contains(key))
      .toList()
    ..sort();
  keys.addAll(extras);
  return keys;
}

String _groupLabel(AppLocalizations l10n, String key) {
  return switch (key) {
    'all' => l10n.orientation_tasks_group_all,
    'general' => l10n.orientation_tasks_group_general,
    'today' => l10n.orientation_tasks_group_today,
    'clubs' => l10n.orientation_tasks_group_clubs,
    'photo' => l10n.orientation_tasks_group_photos,
    'qr' => l10n.orientation_tasks_group_qr,
    _ => key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}',
  };
}

class _ChallengeCell extends ConsumerWidget {
  const _ChallengeCell({required this.challenge});

  final OrientationChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChallengeCard(
      challenge: challenge,
      onTap: () => openChallengeFlow(context, ref, challenge),
    );
  }
}
