import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/events/data/events_service.dart';
import 'package:jaswallet_app/features/events/domain/entities/event.dart';

void main() {
  // ── NuEvent entity ────────────────────────────────────────────────────────

  group('NuEvent', () {
    test('stores all required and optional fields', () {
      const event = NuEvent(
        title: 'Career Fair 2024',
        date: 'Mon, Apr 13',
        venue: 'Red Hall',
        imageUrl: 'https://example.com/image.jpg',
        link: 'https://nuweeklyevents.com/event-details/career-fair',
      );

      expect(event.title, 'Career Fair 2024');
      expect(event.date, 'Mon, Apr 13');
      expect(event.venue, 'Red Hall');
      expect(event.imageUrl, 'https://example.com/image.jpg');
      expect(event.link, contains('career-fair'));
    });

    test('imageUrl and link are nullable', () {
      const event = NuEvent(
        title: 'Lecture',
        date: 'Apr 14',
        venue: '5E.417',
      );
      expect(event.imageUrl, isNull);
      expect(event.link, isNull);
    });
  });

  // ── NuEventDetails entity ─────────────────────────────────────────────────

  group('NuEventDetails', () {
    test('stores required fields and defaults about to empty list', () {
      const details = NuEventDetails(
        title: 'Career Fair',
        date: 'Mon, Apr 13',
        venue: 'Red Hall',
      );
      expect(details.title, 'Career Fair');
      expect(details.about, isEmpty);
    });

    test('stores optional metadata', () {
      const details = NuEventDetails(
        title: 'Workshop',
        date: 'Tue, Apr 14',
        venue: '5E.417',
        language: 'English',
        organizer: 'Department of Student Services',
        fullDateTime: 'Apr 14, 2026, 10:00 AM',
        locationDetails: 'Block 5E, Room 417',
      );
      expect(details.language, 'English');
      expect(details.organizer, 'Department of Student Services');
      expect(details.fullDateTime, contains('10:00'));
      expect(details.locationDetails, contains('5E'));
    });

    test('stores about content blocks', () {
      const details = NuEventDetails(
        title: 'Event',
        date: 'Apr 15',
        venue: 'Block C',
        about: [
          TextBlock('Join us for the annual fair.'),
          LinkTextBlock(
            text: 'Register here',
            url: 'https://example.com/register',
          ),
        ],
      );
      expect(details.about.length, 2);
      expect(details.about[0], isA<TextBlock>());
      expect(details.about[1], isA<LinkTextBlock>());
    });
  });

  // ── ContentBlock subtypes ─────────────────────────────────────────────────

  group('ContentBlock subtypes', () {
    test('TextBlock holds text', () {
      const block = TextBlock('Hello world');
      expect(block.text, 'Hello world');
    });

    test('LinkTextBlock holds text and url', () {
      const block = LinkTextBlock(
        text: 'Click here',
        url: 'https://example.com',
      );
      expect(block.text, 'Click here');
      expect(block.url, 'https://example.com');
    });

    test('TextBlock is a ContentBlock', () {
      const ContentBlock block = TextBlock('hello');
      expect(block, isA<TextBlock>());
    });

    test('LinkTextBlock is a ContentBlock', () {
      const ContentBlock block = LinkTextBlock(text: 'x', url: 'y');
      expect(block, isA<LinkTextBlock>());
    });
  });

  // ── EventsService.fetchEventDetails — null/empty link shortcut ────────────

  group('EventsService.fetchEventDetails — no-network path', () {
    test('returns basic details immediately when link is null', () async {
      final service = EventsService.instance;
      const event = NuEvent(
        title: 'No-link Event',
        date: 'Apr 20',
        venue: 'Online',
        imageUrl: 'https://example.com/img.jpg',
        // link is null
      );

      final details = await service.fetchEventDetails(event);

      expect(details.title, event.title);
      expect(details.date, event.date);
      expect(details.venue, event.venue);
      expect(details.imageUrl, event.imageUrl);
    });

    test('returns basic details immediately when link is empty string', () async {
      final service = EventsService.instance;
      const event = NuEvent(
        title: 'Empty Link Event',
        date: 'Apr 21',
        venue: 'Room 201',
        link: '',
      );

      final details = await service.fetchEventDetails(event);

      expect(details.title, event.title);
      expect(details.venue, event.venue);
    });

    test('caches result: second call with null link returns same object', () async {
      final service = EventsService.instance;
      const event = NuEvent(
        title: 'Cached Event',
        date: 'Apr 22',
        venue: 'Auditorium',
      );

      final first = await service.fetchEventDetails(event);
      final second = await service.fetchEventDetails(event);

      // Both calls return NuEventDetails with the same title
      expect(first.title, second.title);
    });
  });
}
