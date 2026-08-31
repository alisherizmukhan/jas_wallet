import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/orientation_schedule.dart';
import 'orientation_repository_provider.dart';

/// The week's timetable, both tracks. Loaded once — it is a bundled asset and
/// nothing a student does changes it.
final orientationScheduleProvider = FutureProvider<OrientationSchedule>(
  (ref) => ref.watch(orientationRepositoryProvider).getSchedule(),
);

/// Which programme the student is on, and the writer for it.
///
/// Null means they have not said yet, which is what the Home page's track
/// prompt keys off. Kept as a notifier rather than a `FutureProvider` because
/// the answer is written from two places (the prompt on Home and the switcher
/// on the Schedule page) and both have to move every screen at once.
class OrientationTrackNotifier extends StateNotifier<AsyncValue<StudentTrack?>> {
  OrientationTrackNotifier(this._read, this._write) : super(const AsyncValue.loading()) {
    load();
  }

  final Future<StudentTrack?> Function() _read;
  final Future<void> Function(StudentTrack) _write;

  Future<void> load() async {
    try {
      state = AsyncValue.data(await _read());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> select(StudentTrack track) async {
    await _write(track);
    state = AsyncValue.data(track);
  }
}

final orientationTrackProvider =
    StateNotifierProvider<OrientationTrackNotifier, AsyncValue<StudentTrack?>>((ref) {
  final repo = ref.watch(orientationRepositoryProvider);
  return OrientationTrackNotifier(repo.getTrack, repo.setTrack);
});

/// The schedule as *this* student sees it: their own track plus the sessions
/// the grid spans across both columns.
///
/// Returns null while either half is still loading, so a page never renders a
/// half-filtered week — showing Graduate sessions to an undergraduate for one
/// frame is worse than showing a skeleton for one frame.
final orientationMyScheduleProvider = Provider<OrientationSchedule?>((ref) {
  final schedule = ref.watch(orientationScheduleProvider).valueOrNull;
  final track = ref.watch(orientationTrackProvider).valueOrNull;
  if (schedule == null || track == null) return null;

  return OrientationSchedule(
    days: [
      for (final day in schedule.days)
        ScheduleDay(
          date: day.date,
          label: day.label,
          sessions: day.forTrack(track),
        ),
    ],
  );
});
