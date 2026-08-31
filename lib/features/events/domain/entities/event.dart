/// An event parsed from the NU events listing page.
class NuEvent {
  const NuEvent({
    required this.title,
    required this.date,
    required this.venue,
    this.time,
    this.imageUrl,
    this.link,
    this.category,
    this.audience,
  });

  final String title;

  /// Short date from the listing, e.g. "Fri, Jun 12, 2026".
  final String date;

  /// Venue from the listing, e.g. "Red Hall", "Main Hall, Block C2".
  final String venue;

  /// Time from the listing, e.g. "09:00".
  final String? time;

  final String? imageUrl;
  final String? link;

  /// Event category, e.g. "Conferences", "Seminar", "Workshop".
  final String? category;

  /// Intended audience, e.g. "Students, Staff, External guests".
  final String? audience;

  /// Stable identity for follow-state and reminder notification IDs.
  ///
  /// Prefers [link] (unique per listing); falls back to title+date when the
  /// NU page did not publish a URL.
  String get reminderKey {
    final link = this.link;
    if (link != null && link.isNotEmpty) return link;
    return '$title|$date';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content blocks for the "About the event" section
// ─────────────────────────────────────────────────────────────────────────────

sealed class ContentBlock {
  const ContentBlock();
}

class TextBlock extends ContentBlock {
  const TextBlock(this.text);
  final String text;
}

class LinkTextBlock extends ContentBlock {
  const LinkTextBlock({required this.text, required this.url});
  final String text;
  final String url;
}

// ─────────────────────────────────────────────────────────────────────────────
// NuEventDetails: structured detail page data
// ─────────────────────────────────────────────────────────────────────────────

class NuEventDetails {
  const NuEventDetails({
    required this.title,
    required this.date,
    required this.venue,
    this.language,
    this.organizer,
    this.imageUrl,
    this.fullDateTime,
    this.locationDetails,
    this.about = const [],
    this.category,
    this.audience,
  });

  final String title;
  final String date;
  final String venue;
  final String? language;
  final String? organizer;
  final String? imageUrl;
  final String? fullDateTime;
  final String? locationDetails;
  final List<ContentBlock> about;
  final String? category;
  final String? audience;
}
