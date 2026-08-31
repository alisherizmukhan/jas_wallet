import 'package:flutter_test/flutter_test.dart';

import 'package:jaswallet_app/features/orientation_week/data/models/photo_quest_api_mapper.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_mission.dart';
import 'package:jaswallet_app/features/orientation_week/domain/entities/photo_quest_verdict.dart';

/// Does a moderator or CV decision actually reach the student?
///
/// These drive the rule with the exact JSON `GET /orientation/photo-quests`
/// returns, decoded by the real mapper — no stubs of our own shape. The status
/// strings come from `photo_quest_service._mission_status_for_student`:
///
///   PASS / APPROVED  → "completed"      (CV pass, or moderator approve)
///   REVIEW           → "pending_review" (CV grey zone, or a manual mission)
///   REJECTED         → "rejected"       (moderator reject)
///   FAIL             → "available"      (CV fail — student may re-shoot)
///
/// If the backend ever renames one of these, these tests fail rather than the
/// app going quietly silent on every verdict.
void main() {
  Map<String, dynamic> missionJson(String status) => {
        'id': 'pq_sunset_shot',
        'title': 'Sunset Shot',
        'description': 'Capture a sunset from anywhere on campus.',
        'difficulty': 'hard',
        'category': 'sky',
        'icon': 'sunset',
        'reward_tokens': 100,
        'verify_task_id': 'sunset',
        'requirements': <String>[],
        'status': status,
        'submission_count': 1,
        'photo_url': 'https://example.test/media/photo_quests/a.jpg',
      };

  List<PhotoMission> board(String status) => [photoMissionFromApi(missionJson(status))];

  const pending = {'pq_sunset_shot': MissionStatus.pendingReview};

  group('a submission waiting in review', () {
    test('is announced as approved once a moderator approves it', () {
      final verdicts = diffPhotoQuestVerdicts(
        lastSeen: pending,
        missions: board('completed'),
      );

      expect(verdicts, hasLength(1));
      expect(verdicts.single.approved, isTrue);
      expect(verdicts.single.mission.rewardTokens, 100);
    });

    test('is announced as declined once a moderator rejects it', () {
      final verdicts = diffPhotoQuestVerdicts(
        lastSeen: pending,
        missions: board('rejected'),
      );

      expect(verdicts, hasLength(1));
      expect(verdicts.single.approved, isFalse);
    });

    test('is announced as declined on a CV fail, which the API calls "available"', () {
      final verdicts = diffPhotoQuestVerdicts(
        lastSeen: pending,
        missions: board('available'),
      );

      expect(verdicts, hasLength(1));
      expect(verdicts.single.approved, isFalse);
    });

    test('says nothing while it is still in review', () {
      expect(
        diffPhotoQuestVerdicts(lastSeen: pending, missions: board('pending_review')),
        isEmpty,
      );
    });
  });

  group('nothing is announced when there is no news', () {
    test('a mission the device has never seen is recorded silently', () {
      // A fresh install pulling a board of already-finished missions must not
      // fire a notification per mission.
      expect(
        diffPhotoQuestVerdicts(lastSeen: const {}, missions: board('completed')),
        isEmpty,
      );
    });

    test('a verdict already seen is not repeated on the next poll', () {
      expect(
        diffPhotoQuestVerdicts(
          lastSeen: const {'pq_sunset_shot': MissionStatus.completed},
          missions: board('completed'),
        ),
        isEmpty,
      );
    });

    test('a mission that was never pending is not announced', () {
      expect(
        diffPhotoQuestVerdicts(
          lastSeen: const {'pq_sunset_shot': MissionStatus.available},
          missions: board('completed'),
        ),
        isEmpty,
      );
    });
  });

  group('the API status strings the rule depends on', () {
    test('map to the statuses the diff switches on', () {
      expect(photoMissionFromApi(missionJson('completed')).status, MissionStatus.completed);
      expect(photoMissionFromApi(missionJson('pending_review')).status, MissionStatus.pendingReview);
      expect(photoMissionFromApi(missionJson('rejected')).status, MissionStatus.rejected);
      expect(photoMissionFromApi(missionJson('available')).status, MissionStatus.available);
    });

    test('an unrecognised status degrades to available, never to pending', () {
      // Degrading to pending would strand the watcher polling forever; falling
      // back to available at worst costs one missed announcement.
      final mission = photoMissionFromApi(missionJson('something_new'));
      expect(mission.status, MissionStatus.available);
      expect(isPhotoQuestPending(mission.status), isFalse);
    });
  });

  test('a re-shoot after rejection can be announced again', () {
    // submission_count is part of the feed id, so the second verdict on the
    // same mission is not swallowed as a duplicate of the first.
    final second = photoMissionFromApi({...missionJson('completed'), 'submission_count': 2});
    final verdicts = diffPhotoQuestVerdicts(lastSeen: pending, missions: [second]);

    expect(verdicts, hasLength(1));
    expect(verdicts.single.mission.submissionCount, 2);
  });
}
