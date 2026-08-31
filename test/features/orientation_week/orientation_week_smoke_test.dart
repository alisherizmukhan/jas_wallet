import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/presentation/pages/leaderboard_page.dart';
import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/photo_quest_detail_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/photo_quests_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/rewards_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/reward_history_page.dart';

import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_repository_provider.dart';
import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

/// Renders every remaining Orientation Week screen through its real provider
/// / mock repository (not the golden-path flow) purely to catch layout
/// overflow / missing l10n / render errors. No interaction, just "does it
/// render".
void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpAndSettleScreen(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: page),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('Leaderboard renders with podium + list, no overflow', (tester) async {
    await pumpAndSettleScreen(tester, const LeaderboardPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rewards renders prize list, no overflow', (tester) async {
    await pumpAndSettleScreen(tester, const RewardsPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reward history renders (empty state), no overflow', (tester) async {
    await pumpAndSettleScreen(tester, const RewardHistoryPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Photo Quest grid renders every mission, no overflow', (tester) async {
    await pumpAndSettleScreen(tester, const PhotoQuestsPage());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Photo Quest detail renders header + facts, no overflow', (tester) async {
    await pumpAndSettleScreen(tester, PhotoQuestDetailPage(mission: (await OrientationCatalog.photoMissions()).first));
    expect(tester.takeException(), isNull);
  });
}
