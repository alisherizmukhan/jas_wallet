import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/events/data/event_follow_store.dart';
import 'package:jaswallet_app/features/events/domain/entities/event.dart';
import 'package:shared_preferences/shared_preferences.dart';

NuEvent _event({
  String title = 'Orientation Day',
  String date = 'Fri, Jul 10, 2026',
  String? link = 'https://nu.edu.kz/eventsm/orientation-day',
}) =>
    NuEvent(title: title, date: date, venue: 'Main Hall', link: link);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load is empty by default (opt-in)', () async {
    final store = EventFollowStore();
    expect(await store.load(), isEmpty);
  });

  test('toggle follows then unfollows the same event', () async {
    final store = EventFollowStore();
    final event = _event();

    final followed = await store.toggle(event);
    expect(followed.followed, isTrue);
    expect(followed.keys, {event.reminderKey});
    expect(await store.load(), {event.reminderKey});

    final unfollowed = await store.toggle(event);
    expect(unfollowed.followed, isFalse);
    expect(unfollowed.keys, isEmpty);
  });

  test('events without a link use title|date as the key', () async {
    final event = _event(link: null);
    expect(event.reminderKey, 'Orientation Day|Fri, Jul 10, 2026');

    final store = EventFollowStore();
    await store.toggle(event);
    expect(await store.load(), {event.reminderKey});
  });
}
