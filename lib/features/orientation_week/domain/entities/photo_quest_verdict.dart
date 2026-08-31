import 'photo_mission.dart';

/// One mission that left the pending state since the device last looked.
class PhotoQuestVerdict {
  const PhotoQuestVerdict({required this.mission, required this.approved});

  final PhotoMission mission;

  /// True when the photo was accepted — by the CV service or by a moderator.
  final bool approved;
}

/// Whether a mission is still waiting on a decision.
bool isPhotoQuestPending(MissionStatus status) =>
    status == MissionStatus.pendingReview || status == MissionStatus.uploading;

/// Which missions have been decided since [lastSeen] was recorded.
///
/// Kept as a pure function so the whole rule can be tested against the exact
/// payloads the backend produces, rather than only through a widget that needs
/// timers, a router and a live session to exercise.
///
/// Only transitions *out of* a pending state count:
///
///  • A mission the device has never seen is recorded silently — otherwise a
///    fresh install would announce every already-finished mission at once.
///  • A mission that was already decided when we last looked has nothing new
///    to say, however many times it is polled.
///
/// The backend reports a CV `fail` as `available` (the student may simply
/// shoot it again), which from here is the same news as a moderator rejection:
/// this photo did not count.
List<PhotoQuestVerdict> diffPhotoQuestVerdicts({
  required Map<String, MissionStatus> lastSeen,
  required List<PhotoMission> missions,
}) {
  final verdicts = <PhotoQuestVerdict>[];
  for (final mission in missions) {
    final previous = lastSeen[mission.id];
    if (previous == null) continue;
    if (!isPhotoQuestPending(previous) || isPhotoQuestPending(mission.status)) {
      continue;
    }

    switch (mission.status) {
      case MissionStatus.completed:
        verdicts.add(PhotoQuestVerdict(mission: mission, approved: true));
      case MissionStatus.rejected:
      case MissionStatus.available:
        verdicts.add(PhotoQuestVerdict(mission: mission, approved: false));
      case MissionStatus.locked:
      case MissionStatus.expired:
      case MissionStatus.uploading:
      case MissionStatus.pendingReview:
        break;
    }
  }
  return verdicts;
}
