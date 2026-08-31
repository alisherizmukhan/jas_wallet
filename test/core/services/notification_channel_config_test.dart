import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/notification_channel_config.dart';

void main() {
  group('NotificationChannels', () {
    test('all returns 11 channels', () {
      expect(NotificationChannels.all.length, 11);
    });

    test('every channel ID has jaswallet_ prefix', () {
      for (final ch in NotificationChannels.all) {
        expect(ch.id, startsWith('jaswallet_'),
            reason: '${ch.id} should start with jaswallet_');
      }
    });

    test('all channel IDs are unique', () {
      final ids = NotificationChannels.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all channel names are non-empty', () {
      for (final ch in NotificationChannels.all) {
        expect(ch.name, isNotEmpty,
            reason: '${ch.id} must have a non-empty name');
      }
    });

    test('gym channel exists with correct id', () {
      final ids = NotificationChannels.all.map((c) => c.id);
      expect(ids, contains(NotificationChannels.gym));
      expect(NotificationChannels.gym, 'jaswallet_gym');
    });

    test('access channel exists with correct id', () {
      final ids = NotificationChannels.all.map((c) => c.id);
      expect(ids, contains(NotificationChannels.access));
      expect(NotificationChannels.access, 'jaswallet_access');
    });

    test('events channel exists with correct id', () {
      final ids = NotificationChannels.all.map((c) => c.id);
      expect(ids, contains(NotificationChannels.events));
      expect(NotificationChannels.events, 'jaswallet_events');
    });

    test('orientation channel exists and carries a name for showNotification', () {
      final ids = NotificationChannels.all.map((c) => c.id);
      expect(ids, contains(NotificationChannels.orientation));
      expect(NotificationChannels.orientation, 'jaswallet_orientation');
      // Photo Quest verdicts pass this constant straight through, so it has to
      // match the name the channel was created with or Android shows a second,
      // unnamed channel in system settings.
      final channel =
          NotificationChannels.all.firstWhere((c) => c.id == NotificationChannels.orientation);
      expect(channel.name, NotificationChannels.orientationName);
    });

    test('static id constants match channel list entries', () {
      final ids = NotificationChannels.all.map((c) => c.id).toSet();
      expect(ids, containsAll([
        NotificationChannels.general,
        NotificationChannels.meals,
        NotificationChannels.gym,
        NotificationChannels.access,
        NotificationChannels.social,
        NotificationChannels.education,
        NotificationChannels.fintech,
        NotificationChannels.jobs,
        NotificationChannels.reminders,
        NotificationChannels.events,
        NotificationChannels.orientation,
      ]));
    });
  });
}
