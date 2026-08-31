import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/notification_deep_link_handler.dart';

// Tests for NotificationDeepLinkHandler.resolve() — the pure alias-to-path resolver.
// Navigation integration is in notification_deep_link_handler_test.dart.
void main() {
  group('NotificationDeepLinkHandler.resolve()', () {
    // ── null / empty inputs ─────────────────────────────────────────────────

    test('returns null for null input', () {
      expect(NotificationDeepLinkHandler.resolve(null), isNull);
    });

    test('returns null for empty string', () {
      expect(NotificationDeepLinkHandler.resolve(''), isNull);
    });

    test('returns null for whitespace-only string', () {
      expect(NotificationDeepLinkHandler.resolve('   '), isNull);
    });

    // ── known fintech aliases ───────────────────────────────────────────────

    test('fintech alias resolves to /fintech', () {
      expect(NotificationDeepLinkHandler.resolve('fintech'), '/fintech');
    });

    // ── SVC / meal aliases ──────────────────────────────────────────────────

    test('svc alias resolves to /svc', () {
      expect(NotificationDeepLinkHandler.resolve('svc'), '/svc');
    });

    test('social_meal alias resolves to /svc', () {
      expect(NotificationDeepLinkHandler.resolve('social_meal'), '/svc');
    });

    test('svc_streak resolves to /svc/streak', () {
      expect(NotificationDeepLinkHandler.resolve('svc_streak'), '/svc/streak');
    });

    test('svc_history resolves to /svc/history', () {
      expect(NotificationDeepLinkHandler.resolve('svc_history'), '/svc/history');
    });

    test('svc_calendar resolves to /svc/calendar', () {
      expect(NotificationDeepLinkHandler.resolve('svc_calendar'), '/svc/calendar');
    });

    // ── Social / profile aliases ────────────────────────────────────────────

    test('social alias resolves to /profile', () {
      expect(NotificationDeepLinkHandler.resolve('social'), '/profile');
    });

    test('profile alias resolves to /profile', () {
      expect(NotificationDeepLinkHandler.resolve('profile'), '/profile');
    });

    test('conversations alias resolves to /conversations', () {
      expect(NotificationDeepLinkHandler.resolve('conversations'), '/conversations');
    });

    // ── Job finder aliases ──────────────────────────────────────────────────

    test('jobs alias resolves to /job-finder', () {
      expect(NotificationDeepLinkHandler.resolve('jobs'), '/job-finder');
    });

    test('job_finder alias resolves to /job-finder', () {
      expect(NotificationDeepLinkHandler.resolve('job_finder'), '/job-finder');
    });

    // ── Student clubs aliases ───────────────────────────────────────────────

    test('clubs alias resolves to /student-clubs', () {
      expect(NotificationDeepLinkHandler.resolve('clubs'), '/student-clubs');
    });

    test('student_clubs alias resolves to /student-clubs', () {
      expect(NotificationDeepLinkHandler.resolve('student_clubs'), '/student-clubs');
    });

    // ── Gamification aliases ────────────────────────────────────────────────

    test('my_level resolves to /my-level', () {
      expect(NotificationDeepLinkHandler.resolve('my_level'), '/my-level');
    });

    test('gamification alias resolves to /my-level', () {
      expect(NotificationDeepLinkHandler.resolve('gamification'), '/my-level');
    });

    test('tasks alias resolves to /my-level/tasks', () {
      expect(NotificationDeepLinkHandler.resolve('tasks'), '/my-level/tasks');
    });

    test('achievements alias resolves to /my-level/achievements', () {
      expect(NotificationDeepLinkHandler.resolve('achievements'), '/my-level/achievements');
    });

    test('ranking alias resolves to /my-level/ranking', () {
      expect(NotificationDeepLinkHandler.resolve('ranking'), '/my-level/ranking');
    });

    // ── Campus access alias ─────────────────────────────────────────────────

    test('access alias resolves to /access', () {
      expect(NotificationDeepLinkHandler.resolve('access'), '/access');
    });

    // ── Education aliases ───────────────────────────────────────────────────

    test('classroom alias resolves to /classroom', () {
      expect(NotificationDeepLinkHandler.resolve('classroom'), '/classroom');
    });

    test('courses alias resolves to /courses', () {
      expect(NotificationDeepLinkHandler.resolve('courses'), '/courses');
    });

    test('attendance alias resolves to /attendance/student', () {
      expect(NotificationDeepLinkHandler.resolve('attendance'), '/attendance/student');
    });

    // ── General aliases ─────────────────────────────────────────────────────

    test('notifications alias resolves to /notifications', () {
      expect(NotificationDeepLinkHandler.resolve('notifications'), '/notifications');
    });

    test('settings alias resolves to /settings', () {
      expect(NotificationDeepLinkHandler.resolve('settings'), '/settings');
    });

    // ── Case insensitivity ──────────────────────────────────────────────────

    test('FINTECH (uppercase) resolves correctly', () {
      expect(NotificationDeepLinkHandler.resolve('FINTECH'), '/fintech');
    });

    test('Mixed case SVC resolves correctly', () {
      expect(NotificationDeepLinkHandler.resolve('Svc'), '/svc');
    });

    // ── Direct path passthrough ─────────────────────────────────────────────

    test('direct /gym path is passed through unchanged', () {
      expect(NotificationDeepLinkHandler.resolve('/gym'), '/gym');
    });

    test('direct /fintech path is passed through unchanged', () {
      expect(NotificationDeepLinkHandler.resolve('/fintech'), '/fintech');
    });

    test('direct nested /svc/streak path is passed through unchanged', () {
      expect(NotificationDeepLinkHandler.resolve('/svc/streak'), '/svc/streak');
    });

    // ── Unknown alias — passthrough ─────────────────────────────────────────

    test('unknown alias is returned as-is', () {
      expect(NotificationDeepLinkHandler.resolve('unknown_alias'), 'unknown_alias');
    });

    test('unknown path with slash is returned as-is', () {
      expect(NotificationDeepLinkHandler.resolve('/some/deep/path'), '/some/deep/path');
    });
  });
}
