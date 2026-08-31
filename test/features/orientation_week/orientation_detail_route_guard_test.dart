import 'package:flutter_test/flutter_test.dart';

import 'package:jaswallet_app/core/routing/app_router.dart';
import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';
import 'package:jaswallet_app/features/orientation_week/data/mock/mock_rewards.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_mission.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/reward.dart';

import '../../helpers/orientation_catalog_fixture.dart';

/// Reopening the app on a Photo Quest detail page.
///
/// `extra` is in-memory only: lock the screen on the detail page, leave the
/// app long enough for Android to evict it, and the route comes back with its
/// path but a null `extra`. `state.extra as PhotoMission` on that turned into
/// "type 'Null' is not a subtype of type 'PhotoMission' in type cast" painted
/// across the screen — the crash a student sees on resume.
///
/// The guard turns that into a redirect back to the list the page was opened
/// from, which is the only thing there is to show without the mission.
void main() {
  // The JSON catalogue, read off disk — rootBundle would hang here.
  setUp(seedOrientationCatalog);
  group('photo quest detail', () {
    test('stays put when the mission travelled with the route', () async {
      final mission = (await OrientationCatalog.photoMissions()).first;

      expect(
        detailExtraGuard<PhotoMission>(mission, AppRoutes.orientationPhotoQuests),
        isNull,
      );
    });

    test('falls back to the list when the app was restored without it', () {
      expect(
        detailExtraGuard<PhotoMission>(null, AppRoutes.orientationPhotoQuests),
        AppRoutes.orientationPhotoQuests,
      );
    });

    test('falls back when something else entirely arrives in extra', () {
      // A deep link or a mistaken push can put anything here; only the right
      // type may reach the cast.
      expect(
        detailExtraGuard<PhotoMission>(
          <String, dynamic>{'id': 'pq_sunset_shot'},
          AppRoutes.orientationPhotoQuests,
        ),
        AppRoutes.orientationPhotoQuests,
      );
    });
  });

  group('reward detail', () {
    test('stays put when the reward travelled with the route', () {
      expect(
        detailExtraGuard<Reward>(mockRewards().first, AppRoutes.orientationRewards),
        isNull,
      );
    });

    test('falls back to the rewards list when it did not', () {
      expect(
        detailExtraGuard<Reward>(null, AppRoutes.orientationRewards),
        AppRoutes.orientationRewards,
      );
    });

    test('does not accept a photo mission in a reward route', () async {
      final mission = (await OrientationCatalog.photoMissions()).first;
      expect(
        detailExtraGuard<Reward>(mission, AppRoutes.orientationRewards),
        AppRoutes.orientationRewards,
      );
    });
  });
}
