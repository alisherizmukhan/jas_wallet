import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/core/routing/app_router.dart';
import 'package:jaswallet_app/features/orientation_week/config/orientation_links.dart';
import 'package:jaswallet_app/features/orientation_week/data/mock/mock_rewards.dart';
import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/reward_detail_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/reward_history_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/rewards_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_repository_provider.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/reward_row.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

void main() {
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(
          child: const RewardsPage(),
          extraRoutes: {
            AppRoutes.orientationRewardDetail: RewardDetailPage(reward: mockRewards().first),
          },
        ),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('renders prize list and claim card without overflow', (tester) async {
    await pumpPage(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.orientation_rw_token_rewards), findsOneWidget);
    expect(find.byType(RewardRow), findsNWidgets(mockRewards().length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains how a redeemed prize is actually collected', (tester) async {
    await pumpPage(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.orientation_rw_claim_title), findsOneWidget);
    expect(
      find.text(l10n.orientation_rw_claim_step2(OrientationLinks.prizeWhatsAppNumber)),
      findsOneWidget,
    );
    expect(find.text(l10n.orientation_rw_claim_step3), findsOneWidget);
    expect(find.text(l10n.orientation_rw_claim_cta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a reward opens its detail page', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(RewardRow).first);
    await tester.pumpAndSettle();

    expect(find.byType(RewardDetailPage), findsOneWidget);
  });

  void seedRedemptions() {
    SharedPreferences.setMockInitialValues({
      'orientation_reward_redemptions': [
        'reward_gold_cafe_card|2026-07-24T14:30:00.000|1500|OW-GOL-001',
        'reward_airpods_4|2026-07-23T09:05:00.000|2500|OW-AIR-001',
      ],
    });
  }

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: const RewardHistoryPage()),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('history page renders redeemed rewards with no overflow', (tester) async {
    seedRedemptions();
    await pumpHistory(tester);

    expect(find.text('Gold Café Card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history no longer prints a pickup code on the card', (tester) async {
    seedRedemptions();
    await pumpHistory(tester);

    expect(find.text('OW-GOL-001'), findsNothing);
  });

  testWidgets('tapping a redemption shows who redeemed it', (tester) async {
    seedRedemptions();
    await pumpHistory(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text('Gold Café Card'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.orientation_rw_redeemed_by), findsOneWidget);
    expect(find.text(l10n.orientation_rw_field_name), findsOneWidget);
    expect(find.text(l10n.orientation_rw_field_student_id), findsOneWidget);
    expect(find.text(l10n.orientation_rw_field_email), findsOneWidget);
    expect(find.text(l10n.orientation_rw_claim_cta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the redemption sheet keeps a gutter instead of running edge to edge',
      (tester) async {
    seedRedemptions();
    await pumpHistory(tester);

    await tester.tap(find.text('Gold Café Card'));
    await tester.pumpAndSettle();

    final width = tester.getSize(find.byType(FeatureCtaButton)).width;
    expect(width, lessThan(390), reason: 'the sheet content is inset from the screen edges');
    expect(width, 390 - 2 * FeatureStyle.pagePadding);
  });

  testWidgets('detail page blocks redeeming when the balance is too low', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pricey = mockRewards().reduce((a, b) => a.priceTokens >= b.priceTokens ? a : b);
    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: RewardDetailPage(reward: pricey)),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.orientation_rw_need_more(_grouped(pricey.priceTokens))), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Drain any leftover mock-latency timers before the binding tears down.
    await tester.pump(const Duration(seconds: 1));
  });
}

String _grouped(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
