import 'dart:io';

import 'package:jaswallet_app/features/orientation_week/data/mock/orientation_catalog.dart';

/// Loads the real Orientation Week JSON off disk and seeds [OrientationCatalog]
/// with it, synchronously.
///
/// Call this from `setUp` in any test that reaches Orientation Week content.
/// It is not a stub: these are the same four files the app ships, parsed by
/// the same mappers, so a broken JSON edit still fails the suite. The only
/// thing it replaces is *how the bytes arrive* — `rootBundle` is real async
/// I/O, and inside `testWidgets` the clock is fake and never advances it, so
/// a first load from within a pump hangs until the test times out.
///
/// Paths are relative to the package root, which is `flutter test`'s working
/// directory.
void seedOrientationCatalog() {
  String read(String name) =>
      File('assets/data/orientation/$name.json').readAsStringSync();

  OrientationCatalog.seedFromJson(
    bingo: read('bingo'),
    photoQuests: read('photo_quests'),
    challenges: read('challenges'),
    schedule: read('schedule'),
  );
}
