import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event.dart';
import '../providers/events_provider.dart';
import 'event_details_page.dart';

/// Resolves an event-details deep link (`/events/detail?link=…`) into an
/// [EventDetailsPage] when only the event URL is known — the notification
/// tap path, where a [NuEvent] object cannot travel through the route.
///
/// Waits for the events list (the cache restores in milliseconds on cold
/// start), matches by link, and — when the event has already left the
/// listing — falls back to a link-only event: [EventDetailsPage] fetches its
/// full content (title, date, venue, image, description) from the event URL
/// itself, so the page still renders completely.
class EventDetailsLoaderPage extends ConsumerWidget {
  const EventDetailsLoaderPage({required this.link, super.key});

  /// The nu.edu.kz event URL carried by the notification payload.
  final String? link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = this.link;
    if (link == null || link.isEmpty) {
      // Malformed deep link — nothing to resolve; return to where we were.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final events = ref.watch(eventsProvider).events;
    if (events == null) {
      // Cache restore / first fetch still in flight.
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    NuEvent? match;
    for (final e in events) {
      if (e.link == link) {
        match = e;
        break;
      }
    }
    return EventDetailsPage(
      event: match ?? NuEvent(title: '', date: '', venue: '', link: link),
    );
  }
}
