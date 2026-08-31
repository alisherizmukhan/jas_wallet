import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/orientation_overview_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_repository_provider.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/orientation_partner_card.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

void main() {
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home loads without quick access or the always-on schedule block', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: const OrientationOverviewPage()),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text('Club Fair'), findsOneWidget);
    expect(find.text(l10n.orientation_overall_progress.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.orientation_quick_access), findsNothing);
    expect(find.text(l10n.orientation_schedule_always), findsNothing);
  });

  testWidgets('Overview credits the collaboration with ADSL', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: const OrientationOverviewPage()),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.orientation_partner_title), findsOneWidget);
    expect(find.byType(OrientationPartnerCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
