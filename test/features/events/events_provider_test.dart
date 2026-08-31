import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/home_cache_service.dart';
import 'package:jaswallet_app/features/events/data/events_service.dart';
import 'package:jaswallet_app/features/events/domain/entities/event.dart';
import 'package:jaswallet_app/features/events/presentation/providers/events_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake EventsService ────────────────────────────────────────────────────────

class _FakeEventsService extends EventsService {
  _FakeEventsService() : super.forTesting();

  List<NuEvent> toReturn = [];
  bool shouldThrow = false;
  int fetchCallCount = 0;

  @override
  Future<List<NuEvent>> refresh() async {
    fetchCallCount++;
    if (shouldThrow) throw Exception('network error');
    return List<NuEvent>.from(toReturn);
  }

  @override
  Future<List<NuEvent>> fetchEvents() => refresh();
}

// ── Helper ────────────────────────────────────────────────────────────────────

NuEvent _makeEvent(String id) => NuEvent(
      title: 'Event $id',
      date: 'Mon, Jan 1',
      venue: 'Hall A',
      imageUrl: 'https://example.com/$id.jpg',
    );

ProviderContainer _makeContainer(_FakeEventsService fake) {
  return ProviderContainer(
    overrides: [
      eventsServiceProvider.overrideWithValue(fake),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Offline-first: load from cache ──────────────────────────────────────

  group('EventsNotifier — offline-first cache load', () {
    test('emits data from cache immediately before network completes',
        () async {
      final event = _makeEvent('e1');
      await HomeCacheService.saveEventsJson(
        jsonEncode([
          {'title': event.title, 'date': event.date, 'venue': event.venue},
        ]),
      );

      final fake = _FakeEventsService()
        ..toReturn = [] // network returns nothing different
        ..shouldThrow = true; // make network fail
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      container.read(eventsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventsProvider);
      expect(state.events, isNotNull);
      expect(state.events?.first.title, equals(event.title));
    });

    test('shows loading then empty when cache is missing and network fails',
        () async {
      final fake = _FakeEventsService()..shouldThrow = true;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      // Immediately after creation: still loading (cache check is async).
      expect(container.read(eventsProvider).isInitialLoading, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventsProvider);
      expect(state.events, isNotNull);
      expect(state.events, isEmpty);
    });
  });

  // ── Background network refresh ────────────────────────────────────────────

  group('EventsNotifier — background network refresh', () {
    test('updates state with network data when cache exists', () async {
      await HomeCacheService.saveEventsJson(
        jsonEncode([
          {'title': 'Old', 'date': 'd', 'venue': 'v'},
        ]),
      );

      final fresh = _makeEvent('new');
      final fake = _FakeEventsService()..toReturn = [fresh];
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      container.read(eventsProvider); // trigger lazy init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventsProvider);
      expect(state.events?.first.title, equals(fresh.title));
    });

    test('saves network result to persistent cache', () async {
      final event = _makeEvent('cached');
      final fake = _FakeEventsService()..toReturn = [event];
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      container.read(eventsProvider); // trigger lazy init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final savedJson = await HomeCacheService.loadEventsJson();
      expect(savedJson, isNotNull);
      final decoded = (jsonDecode(savedJson!) as List<dynamic>).cast<Map<String, dynamic>>();
      expect(decoded.first['title'], equals(event.title));
    });

    test('keeps cached state on network error', () async {
      await HomeCacheService.saveEventsJson(
        jsonEncode([
          {'title': 'Cached', 'date': 'd', 'venue': 'v'},
        ]),
      );
      final fake = _FakeEventsService()..shouldThrow = true;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      container.read(eventsProvider); // trigger lazy init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventsProvider);
      expect(state.events, isNotNull);
      expect(state.events?.first.title, equals('Cached'));
    });

    test('does not overwrite persistent cache when network fails', () async {
      await HomeCacheService.saveEventsJson(
        jsonEncode([
          {'title': 'Cached Event', 'date': 'd', 'venue': 'v'},
        ]),
      );
      final fake = _FakeEventsService()..shouldThrow = true;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      container.read(eventsProvider); // trigger lazy init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final savedJson = await HomeCacheService.loadEventsJson();
      expect(savedJson, isNotNull);
      final decoded =
          (jsonDecode(savedJson!) as List).cast<Map<String, dynamic>>();
      expect(decoded.first['title'], equals('Cached Event'));
    });
  });

  // ── Explicit refresh ──────────────────────────────────────────────────────

  group('EventsNotifier.refresh', () {
    test('calls service and updates state', () async {
      final initial = _makeEvent('init');
      final updated = _makeEvent('updated');
      final fake = _FakeEventsService()..toReturn = [initial];
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      fake.toReturn = [updated];
      await container.read(eventsProvider.notifier).refresh();

      expect(
        container.read(eventsProvider).events?.first.title,
        equals(updated.title),
      );
    });

    test('does not throw when network fails', () async {
      final fake = _FakeEventsService()..shouldThrow = true;
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        () async => container.read(eventsProvider.notifier).refresh(),
        returnsNormally,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  // ── Logout cache cleanup ──────────────────────────────────────────────────

  group('HomeCacheService.clearAll — logout cleanup', () {
    test('clearAll removes saved events so next load returns null', () async {
      await HomeCacheService.saveEventsJson('[]');
      expect(await HomeCacheService.loadEventsJson(), isNotNull);

      await HomeCacheService.clearAll();

      expect(await HomeCacheService.loadEventsJson(), isNull);
    });

    test('clearAll does not affect weather/exchange data from this test', () async {
      await HomeCacheService.saveWeatherJson('{"temperature":20}');
      await HomeCacheService.saveEventsJson('[]');

      await HomeCacheService.clearAll();

      // Both cleared (different keys but same prefix).
      expect(await HomeCacheService.loadWeatherJson(), isNull);
      expect(await HomeCacheService.loadEventsJson(), isNull);
    });
  });
}
