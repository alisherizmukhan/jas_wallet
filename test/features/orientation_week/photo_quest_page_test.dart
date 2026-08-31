import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';
import 'package:jaswallet_app/features/orientation_week/data/services/photo_quest_status_store.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_mission.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/photo_quest_detail_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/pages/photo_quests_page.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_photo_quests_provider.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/mission_difficulty_tabs.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/widgets/photo_mission_card.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import 'package:jaswallet_app/features/orientation_week/data/repositories/orientation_repository_mock_impl.dart';
import 'package:jaswallet_app/features/orientation_week/presentation/providers/orientation_repository_provider.dart';
import '../../helpers/test_app.dart';
import '../../helpers/orientation_catalog_fixture.dart';

/// Renders the real page through its real provider and mock repository. The
/// two-column grid is the layout most at risk here, so every case runs on a
/// narrow phone viewport.
void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpPage(WidgetTester tester, {Size size = const Size(360, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        router: testRouter(child: const PhotoQuestsPage()),
        overrides: [
          orientationRepositoryProvider.overrideWithValue(OrientationRepositoryMockImpl()),
        ],
      ),
    );
    // Skeletons shimmer forever, so step past the mock latency with fixed
    // pumps before switching to pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('renders one card per mission with no overflow on a narrow phone', (tester) async {
    await pumpPage(tester);

    expect(find.byType(PhotoMissionCard), findsNWidgets((await OrientationCatalog.photoMissions()).length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero and progress card are present', (tester) async {
    await pumpPage(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.orientation_pq_progress_title), findsOneWidget);
    // A fresh install has nothing completed yet.
    final missionCount = (await OrientationCatalog.photoMissions()).length;
    expect(find.text(l10n.orientation_pq_missions_completed(0, missionCount)), findsOneWidget);
  });

  testWidgets('the difficulty filter narrows the grid to that difficulty', (tester) async {
    await pumpPage(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final hardCount = (await OrientationCatalog.photoMissions())
        .where((m) => m.difficulty == MissionDifficulty.hard)
        .length;
    expect(hardCount, greaterThan(0));

    // Difficulty names also appear as chips on the mission cells, so every
    // finder here is scoped to the tab row.
    Finder tab(String label) => find.descendant(
          of: find.byType(MissionDifficultyTabs),
          matching: find.text(label),
        );

    // The filter row scrolls horizontally, so the last tab sits off-screen on
    // a narrow phone — scroll it in before tapping, or the tap lands outside
    // the viewport and is silently swallowed.
    await tester.ensureVisible(tab(l10n.orientation_pq_hard));
    await tester.pumpAndSettle();
    await tester.tap(tab(l10n.orientation_pq_hard));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoMissionCard), findsNWidgets(hardCount));
    expect(tester.takeException(), isNull);

    // "All Missions" restores the full grid.
    await tester.ensureVisible(tab(l10n.orientation_pq_all_missions));
    await tester.pumpAndSettle();
    await tester.tap(tab(l10n.orientation_pq_all_missions));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoMissionCard), findsNWidgets((await OrientationCatalog.photoMissions()).length));
  });

  test('filtered() sinks completed missions to the bottom, order preserved', () async {
    final missions = await OrientationCatalog.photoMissions();
    // Mark a couple mid-list as done so the sort has something to move.
    final withDone = [
      for (var i = 0; i < missions.length; i++)
        if (i == 1 || i == 3) missions[i].copyWith(status: MissionStatus.completed) else missions[i],
    ];
    final state = PhotoQuestState(
      missions: withDone,
      isLoading: false,
      submittingMissionId: null,
    );

    final result = state.filtered(null);

    expect(result.length, withDone.length);
    final firstDone = result.indexWhere((m) => m.status == MissionStatus.completed);
    expect(firstDone, greaterThan(-1));
    // Everything after the first completed mission is also completed.
    expect(
      result.skip(firstDone).every((m) => m.status == MissionStatus.completed),
      isTrue,
      reason: 'completed missions must form one block at the end',
    );
    // Authored order survives inside each group.
    expect(
      result.take(firstDone).map((m) => m.id).toList(),
      withDone.where((m) => m.status != MissionStatus.completed).map((m) => m.id).toList(),
    );
  });

  group('card status is carried by the border, not a caption', () {
    /// One card on its own, at a chosen status, so the border can be read
    /// straight off the painted decoration.
    Future<BoxDecoration> pumpCard(WidgetTester tester, MissionStatus status) async {
      final mission = (await OrientationCatalog.photoMissions()).first.copyWith(status: status);
      await tester.pumpWidget(
        buildTestApp(
          router: testRouter(
            child: Scaffold(
              body: SizedBox(
                width: 180,
                child: PhotoMissionCard(mission: mission, isSubmitting: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(PhotoMissionCard),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('pending review draws an amber border', (tester) async {
      final decoration = await pumpCard(tester, MissionStatus.pendingReview);
      expect(decoration.border!.top.color, AppColors.orange);
      expect(decoration.border!.top.width, greaterThan(1));
    });

    testWidgets('a rejected photo draws a red border', (tester) async {
      final decoration = await pumpCard(tester, MissionStatus.rejected);
      expect(decoration.border!.top.color, AppColors.error);
    });

    testWidgets('an open mission keeps the plain hairline', (tester) async {
      final decoration = await pumpCard(tester, MissionStatus.available);
      expect(decoration.border, FeatureStyle.cardBorder);
    });

    testWidgets('a completed mission keeps the hairline and recedes instead', (tester) async {
      final decoration = await pumpCard(tester, MissionStatus.completed);
      expect(decoration.border, FeatureStyle.cardBorder);

      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(PhotoMissionCard),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, lessThan(1));
    });

    testWidgets('no status caption is rendered on any card', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      for (final status in [
        MissionStatus.pendingReview,
        MissionStatus.rejected,
        MissionStatus.completed,
      ]) {
        await pumpCard(tester, status);
        expect(find.text(l10n.orientation_pq_status_pending), findsNothing);
        expect(find.text(l10n.orientation_pq_status_rejected), findsNothing);
        expect(find.text(l10n.orientation_pq_completed), findsNothing);
      }
    });
  });

  group('a verified mission cannot be re-shot', () {
    /// The detail page reads live mission state from the provider, so the
    /// repository is seeded to the status under test rather than the page
    /// being handed a detached entity.
    Future<void> pumpDetail(WidgetTester tester, MissionStatus status) async {
      final mission = (await OrientationCatalog.photoMissions()).first.copyWith(status: status);
      await tester.pumpWidget(
        buildTestApp(
          router: testRouter(child: PhotoQuestDetailPage(mission: mission)),
          overrides: [
            orientationRepositoryProvider.overrideWithValue(_FixedStatusRepo(mission)),
          ],
        ),
      );
      // The app bar's token pill loads the dashboard through the mock's
      // artificial latency; step past it before settling, as pumpPage does.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }

    // "Take Photo" is also the placeholder copy inside the header frame when a
    // mission has no photo yet, so every button assertion is scoped to the CTA.
    Finder cta(String label) => find.descendant(
          of: find.byType(FeatureCtaButton),
          matching: find.text(label),
        );

    testWidgets('completed shows the verified badge and no capture button', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpDetail(tester, MissionStatus.completed);

      expect(find.text(l10n.orientation_pq_completed), findsOneWidget);
      expect(find.byType(FeatureCtaButton), findsNothing);
    });

    testWidgets('a rejected photo offers a retake', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpDetail(tester, MissionStatus.rejected);

      expect(cta(l10n.orientation_pq_retake), findsOneWidget);
    });

    testWidgets('a CV fail — reported as available — offers a fresh capture', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpDetail(tester, MissionStatus.available);

      expect(cta(l10n.orientation_pq_take_photo), findsOneWidget);
    });

    testWidgets('pending review offers neither', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpDetail(tester, MissionStatus.pendingReview);

      expect(find.text(l10n.orientation_pq_status_pending), findsOneWidget);
      expect(find.byType(FeatureCtaButton), findsNothing);
    });
  });

  group('PhotoQuestStatusStore', () {
    test('round-trips a snapshot so each verdict is announced once', () async {
      const store = PhotoQuestStatusStore();

      // First run: nothing recorded, so the watcher has no baseline to diff
      // against and must stay quiet rather than announce every finished
      // mission at once.
      expect(await store.read(), isEmpty);

      await store.write({
        'pq_sunset_shot': MissionStatus.pendingReview,
        'pq_architecture': MissionStatus.completed,
      });

      expect(await store.read(), {
        'pq_sunset_shot': MissionStatus.pendingReview,
        'pq_architecture': MissionStatus.completed,
      });
    });

    test('sign-out clears it so the next student starts clean', () async {
      const store = PhotoQuestStatusStore();
      await store.write({'pq_sunset_shot': MissionStatus.completed});
      await store.clear();
      expect(await store.read(), isEmpty);
    });

    test('a corrupt snapshot degrades to empty rather than throwing', () async {
      SharedPreferences.setMockInitialValues({
        'orientation_pq_last_seen_status_v1': 'not json at all',
      });
      expect(await const PhotoQuestStatusStore().read(), isEmpty);
    });
  });

  testWidgets('no mission asks a student to identify or approach a specific stranger', (tester) async {
    // Photo Quest has no verification beyond the photo itself, so a mission
    // can require a *scene* — a group of five, a crowd shot — but not
    // identifying, meeting or scanning one particular person. Tasks shaped
    // like that (a senior student, someone from another school, a new
    // friend) belong to Challenges, which can actually check who was found.
    const banned = ['friend', 'friends', 'someone', 'students', 'meet ', 'conversation'];
    for (final mission in await OrientationCatalog.photoMissions()) {
      final text = '${mission.title} ${mission.description}'.toLowerCase();
      for (final word in banned) {
        expect(text.contains(word), isFalse, reason: '"${mission.title}" mentions "$word"');
      }
    }
  });
}

/// The mock repository with one mission pinned to a chosen status.
///
/// Everything else (dashboard, tokens) keeps the real mock behaviour, so the
/// detail page's app bar and providers load exactly as they do in the app.
class _FixedStatusRepo extends OrientationRepositoryMockImpl {
  _FixedStatusRepo(this.mission);

  final PhotoMission mission;

  @override
  Future<List<PhotoMission>> getPhotoMissions() async => [mission];

  @override
  Future<({List<PhotoMission> missions, int bonusTokens})> getPhotoQuestBoard() async =>
      (missions: [mission], bonusTokens: kPhotoQuestBonusTokens);
}
