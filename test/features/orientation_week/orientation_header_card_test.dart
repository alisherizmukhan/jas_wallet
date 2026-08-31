import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/presentation/widgets/orientation_about_card.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/orientation_partner_card.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/reward_claim_card.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

/// The four cards that introduce something rather than being it: What is
/// Orientation Week, In collaboration with ADSL, How to get your prize, and
/// Redemption History.
///
/// Two sit on the Overview and two on Rewards, so nothing on screen ever
/// compares them side by side — which is exactly how they drifted to four
/// different heights. They are one widget now, and these pin that.
void main() {
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Renders [card] the way the pages do — one fixed-width column inside a
  /// scroll view, so its height comes from its content and not from whatever
  /// box it was dropped into.
  Future<double> heightOf(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 360, child: card),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byWidget(card)).height;
  }

  testWidgets('the four cards agree on one collapsed height', (tester) async {
    final about = await heightOf(
      tester,
      const OrientationAboutCard(collapsed: true, onToggle: _noop),
    );
    final partner = await heightOf(tester, const OrientationPartnerCard());
    final claim = await heightOf(tester, const RewardClaimCard());
    final history = await heightOf(
      tester,
      const FeatureHeaderCard(icon: AppIcons.history, title: 'Redemption History', onTap: _noop),
    );

    // The 1px hairline top and bottom sit outside the header box.
    const expected = FeatureHeaderCard.headerHeight + 2;
    expect(about, expected);
    expect(partner, expected, reason: 'a logo in the glyph slot must not resize the card');
    expect(claim, expected, reason: 'a folded card is the same height as a navigational one');
    expect(history, expected);
  });

  testWidgets('a long title wraps inside the card without growing it', (tester) async {
    // Kazakh and Russian run longer than English, and a card that grows for
    // one language breaks the set in that language only.
    final height = await heightOf(
      tester,
      const FeatureHeaderCard(
        icon: AppIcons.gift,
        title: 'A title long enough to need a second line on a narrow phone screen',
        onTap: _noop,
      ),
    );

    expect(height, FeatureHeaderCard.headerHeight + 2);
  });

  testWidgets('How to get your prize opens and closes, like the Overview explainer',
      (tester) async {
    const card = RewardClaimCard();
    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(
          child: const Scaffold(
            body: SingleChildScrollView(child: SizedBox(width: 360, child: card)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    double height() => tester.getSize(find.byWidget(card)).height;

    expect(find.text(l10n.orientation_rw_claim_title), findsOneWidget);
    expect(height(), FeatureHeaderCard.headerHeight + 2);

    // `AnimatedCrossFade` builds both children whatever it is showing, so
    // "is the body visible" is a question about the card's height, not about
    // whether the widget exists.
    await tester.tap(find.text(l10n.orientation_rw_claim_title));
    await tester.pumpAndSettle();
    final open = height();
    expect(open, greaterThan(FeatureHeaderCard.headerHeight + 2));
    expect(tester.getSize(find.text(l10n.orientation_rw_claim_step1)).height, greaterThan(0));

    await tester.tap(find.text(l10n.orientation_rw_claim_title));
    await tester.pumpAndSettle();
    expect(height(), lessThan(open));
    expect(height(), FeatureHeaderCard.headerHeight + 2);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
