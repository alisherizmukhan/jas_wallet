// ignore_for_file: empty_catches
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';

import '../domain/entities/event.dart';

/// Fetches and parses NU events from nu.edu.kz.
///
/// Page 1: static listing page (inf-media/events-page/).
/// Page 2+: AJAX endpoint (wp-admin/admin-ajax.php?action=nu_events_filter&mode=upcoming&paged=N).
/// Both return HTML with `article.nu-event-card` elements.
class EventsService {
  EventsService._();

  @visibleForTesting
  EventsService.forTesting() : this._();

  static final instance = EventsService._();

  static const _baseUrl = 'https://nu.edu.kz';
  static const _ajaxUrl = '$_baseUrl/wp-admin/admin-ajax.php';

  final _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10);

  // ── Pagination state ────────────────────────────────────────────────────────

  int _currentPage = 0;
  bool _hasMorePages = true;
  final Set<String> _seenLinks = {};
  final List<NuEvent> _loadedEvents = [];
  Future<List<NuEvent>>? _pendingPage1;

  bool get hasMore => _hasMorePages;

  // ── List fetching ───────────────────────────────────────────────────────────

  Future<List<NuEvent>> fetchEvents() {
    if (_currentPage > 0) {
      return Future.value(List<NuEvent>.unmodifiable(_loadedEvents));
    }
    final existing = _pendingPage1;
    if (existing != null) return existing;
    final future = _doFetchPage1();
    _pendingPage1 = future;
    return future;
  }

  Future<List<NuEvent>> _doFetchPage1() async {
    try {
      final newEvents = await _fetchOnePage(1);
      _currentPage = 1;
      _loadedEvents.addAll(newEvents);
      if (newEvents.isEmpty) { _hasMorePages = false; }
      return List<NuEvent>.unmodifiable(_loadedEvents);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <NuEvent>[];
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      _pendingPage1 = null;
    }
  }

  Future<(List<NuEvent> all, bool hasMore)> fetchNextPage() async {
    if (!_hasMorePages) {
      return (List<NuEvent>.unmodifiable(_loadedEvents), false);
    }

    final nextPage = _currentPage + 1;
    try {
      final newEvents = await _fetchOnePage(nextPage);
      _currentPage = nextPage;
      _loadedEvents.addAll(newEvents);
      if (newEvents.isEmpty) { _hasMorePages = false; }
    } catch (e) {
      _hasMorePages = false;
    }

    return (List<NuEvent>.unmodifiable(_loadedEvents), _hasMorePages);
  }

  Future<List<NuEvent>> refresh() async {
    _currentPage = 0;
    _hasMorePages = true;
    _seenLinks.clear();
    _loadedEvents.clear();
    _pendingPage1 = null;
    _detailsCache.clear();
    _pendingDetails.clear();
    return fetchEvents();
  }

  // ── Details cache ───────────────────────────────────────────────────────────

  final Map<String, NuEventDetails> _detailsCache = {};
  final Map<String, Future<NuEventDetails>> _pendingDetails = {};

  Future<NuEventDetails> fetchEventDetails(NuEvent event) {
    final url = event.link;
    if (url == null || url.isEmpty) {
      return Future.value(NuEventDetails(
        title: event.title,
        date: event.date,
        venue: event.venue,
        imageUrl: event.imageUrl,
      ));
    }

    final cached = _detailsCache[url];
    if (cached != null) return Future.value(cached);

    return _pendingDetails[url] ??= _doFetchDetails(url, event).then((d) {
      _detailsCache[url] = d;
      _pendingDetails.remove(url);
      return d;
    }).catchError((Object e) {
      _pendingDetails.remove(url);
      return NuEventDetails(
        title: event.title,
        date: event.date,
        venue: event.venue,
        imageUrl: event.imageUrl,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTING PAGE FETCHING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<NuEvent>> _fetchOnePage(int page) async {
    // Use the same AJAX endpoint for all pages — consistent HTML format,
    // avoids WordPress page-template overhead on page 1.
    final url = '$_ajaxUrl?action=nu_events_filter&mode=upcoming&paged=$page';
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'X-Requested-With': 'XMLHttpRequest'},
      ),
    );
    final html = response.data;
    if (response.statusCode == 404 || html == null || html.isEmpty) return [];
    return _parseListPage(html, _seenLinks);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTING PAGE PARSING
  //
  // HTML structure (both static page and AJAX response):
  //   <article class="nu-event-card">
  //     <a href="/eventsm/..." class="nu-event-image"><img srcset="..." src="..."></a>
  //     <div class="nu-event-content">
  //       <div class="nu-event-title"><a href="/eventsm/...">Title</a></div>
  //       <div class="nu-event-meta-list">
  //         <div class="nu-event-meta-row">
  //           <span class="nu-meta-icon"><img src=".../ic-calendar.png"></span>
  //           <span>Fri, Jun 12, 2026</span>   ← sibling span has the text
  //         </div>
  //         <div class="nu-event-meta-row">
  //           <span class="nu-meta-icon"><img src=".../ic-clock.png"></span>
  //           <span>09:00</span>
  //         </div>
  //         <div class="nu-event-meta-row">
  //           <span class="nu-meta-icon"><img src=".../ic-map.png"></span>
  //           <span>Main Hall, Block C2</span>
  //         </div>
  //       </div>
  //     </div>
  //   </article>
  // ═══════════════════════════════════════════════════════════════════════════

  List<NuEvent> _parseListPage(String rawHtml, Set<String> seenLinks) {
    try {
      final document = html_parser.parse(rawHtml);
      final cards = document.querySelectorAll('article.nu-event-card');

      final pageEvents = <NuEvent>[];

      for (final card in cards) {
        try {
          // ── Title + link ─────────────────────────────────────────────────
          final titleLink = card.querySelector('.nu-event-title a');
          final title = titleLink?.text.trim() ?? '';
          if (title.isEmpty) continue;

          final rawHref = titleLink?.attributes['href'] ??
              card.querySelector('a[href*="/eventsm/"]')?.attributes['href'] ?? '';
          if (rawHref.isEmpty) continue;

          final link = _resolveUrl(rawHref);
          if (link == null || !seenLinks.add(link)) continue;

          // ── Category (from .nu-event-category) ──────────────────────────
          final rawCategory = card.querySelector('.nu-event-category')?.text.trim();
          final category = (rawCategory != null &&
                  rawCategory.isNotEmpty &&
                  rawCategory.toLowerCase() != 'category')
              ? rawCategory
              : null;

          // ── Meta rows (date / time / venue / audience) ────────────────────
          // Structure: <div class="nu-event-meta-row">
          //              <span class="nu-meta-icon"><img src="ic-calendar.png"></span>
          //              <span>Fri, Jun 12, 2026</span>
          //            </div>
          // The icon span has no text; sibling span carries the value.
          // row.text concatenates all child text → just the value string.
          String date = '';
          String? time;
          String venue = '';
          String? audience;

          for (final row in card.querySelectorAll('.nu-event-meta-row')) {
            final iconImg = row.querySelector('.nu-meta-icon img');
            final src = (iconImg?.attributes['src'] ?? '').toLowerCase();
            final text = row.text.trim();
            if (text.isEmpty) continue;

            if (src.contains('ic-calendar')) {
              date = text;
            } else if (src.contains('ic-clock')) {
              time = text;
            } else if (src.contains('ic-map')) {
              venue = text;
            } else if (src.contains('ic-group')) {
              audience = text;
            }
          }

          // Regex fallback if meta-row approach found nothing
          if (date.isEmpty) {
            date = _extractDateFromText(card.text) ?? '';
          }


          if (date.isNotEmpty && _isPastEvent(date)) {
            continue;
          }

          // ── Image ────────────────────────────────────────────────────────
          // Prefer 768w from srcset; fall back to src.
          final imgEl = card.querySelector('.nu-event-image img');
          String? imageUrl;
          if (imgEl != null) {
            final srcset = imgEl.attributes['srcset'] ?? '';
            imageUrl = _extract768wFromSrcset(srcset);
            if (imageUrl == null) {
              final src = imgEl.attributes['src'] ?? '';
              if (_isRealEventPhoto(src)) imageUrl = _thumbnailUrl(src);
            }
          }


          pageEvents.add(NuEvent(
            title: title,
            date: date,
            venue: venue,
            time: time,
            imageUrl: imageUrl,
            link: link,
            category: category,
            audience: audience,
          ));
        } catch (e) {
        }
      }

      return pageEvents;
    } catch (_) {
      return [];
    }
  }

  /// Extracts the 768w URL from a srcset string.
  String? _extract768wFromSrcset(String srcset) {
    if (srcset.isEmpty) return null;
    for (final part in srcset.split(',')) {
      final trimmed = part.trim();
      // "https://...768x432.png 768w"
      if (trimmed.endsWith(' 768w')) {
        final url = trimmed.split(' ').first;
        if (_isRealEventPhoto(url)) return url;
      }
    }
    return null;
  }

  /// Returns true if [src] is a real uploaded event photo (not a theme icon).
  bool _isRealEventPhoto(String src) {
    if (src.isEmpty) return false;
    if (!RegExp(r'wp-content/uploads/\d{4}/').hasMatch(src)) return false;
    final filename = src.split('/').last.toLowerCase();
    if (filename.startsWith('ic-') || filename.startsWith('icon-')) return false;
    if (filename.contains('calendar') || filename.contains('clock') ||
        filename.contains('-map') || filename.contains('location') ||
        filename.contains('placeholder')) { return false; }
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE REGEX FALLBACK
  // ═══════════════════════════════════════════════════════════════════════════

  static final _dateRegex = RegExp(
    r'(?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s+)?'
    r'(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
    r'Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'\.?\s+\d{1,2}(?:–\d{1,2})?,?\s+\d{4}',
    caseSensitive: false,
  );

  String? _extractDateFromText(String text) {
    final match = _dateRegex.firstMatch(text);
    if (match == null) return null;
    return match.group(0)!.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DETAIL PAGE PARSING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<NuEventDetails> _doFetchDetails(String url, NuEvent event) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data;
    if (html == null || html.isEmpty) {
      return NuEventDetails(
        title: event.title,
        date: event.date,
        venue: event.venue,
        imageUrl: event.imageUrl,
      );
    }
    return _parseDetails(html, event: event);
  }

  NuEventDetails _parseDetails(String rawHtml, {required NuEvent event}) {
    final document = html_parser.parse(rawHtml);
    final body = document.body;

    // ── 1. Title ──
    final titleEl = document.querySelector('h1') ?? document.querySelector('h2');
    final title = (titleEl != null && titleEl.text.trim().isNotEmpty)
        ? titleEl.text.trim()
        : event.title;

    // ── 2. Date, time, location ──
    // The detail page also uses the same .nu-event-meta-row structure,
    // but fall back to the generic icon-based scan for older layouts.
    String? detailDate;
    String? detailTime;
    String? locationDetails;
    String? detailAudience;

    if (body != null) {
      // Try card-based meta rows first (same structure as listing)
      for (final row in body.querySelectorAll('.nu-event-meta-row')) {
        final iconImg = row.querySelector('.nu-meta-icon img');
        final src = (iconImg?.attributes['src'] ?? '').toLowerCase();
        final text = row.text.trim();
        if (text.isEmpty) continue;
        if (src.contains('ic-calendar') && detailDate == null) { detailDate = text; }
        else if (src.contains('ic-clock') && detailTime == null) { detailTime = text; }
        else if (src.contains('ic-map') && locationDetails == null) { locationDetails = text; }
      }

      // Fallback: generic icon scan with grandparent-text approach
      // Audience from meta rows
      for (final row in body.querySelectorAll('.nu-event-meta-row')) {
        final iconImg = row.querySelector('.nu-meta-icon img');
        final src = (iconImg?.attributes['src'] ?? '').toLowerCase();
        final text = row.text.trim();
        if (text.isEmpty) continue;
        if (src.contains('ic-group') && detailAudience == null) { detailAudience = text; }
      }

      detailDate ??= _iconTextFromGrandparent(body, ['ic-calendar', 'calendar']);
      detailTime ??= _iconTextFromGrandparent(body, ['ic-clock', 'clock']);
      locationDetails ??= _iconTextFromGrandparent(body, ['ic-map', 'ic-location', 'map']);

      // Fallback: <time> element
      if (detailDate == null || detailDate.isEmpty) {
        final timeEl = body.querySelector('time');
        if (timeEl != null) {
          final dt = timeEl.attributes['datetime'] ?? timeEl.text.trim();
          if (dt.isNotEmpty) detailDate = dt;
        }
      }

      // Fallback: regex
      if (detailDate == null || detailDate.isEmpty) {
        final snippet = body.text;
        detailDate = _extractDateFromText(
          snippet.length > 3000 ? snippet.substring(0, 3000) : snippet,
        );
      }

      if (locationDetails != null && _isNuFooterText(locationDetails)) {
        locationDetails = null;
      }
    }

    // ── 3. Hero image ──
    String? detailImageUrl = event.imageUrl;
    if (detailImageUrl == null || !_isRealEventPhoto(detailImageUrl)) {
      final contentEl = document.querySelector('article') ??
          document.querySelector('.entry-content') ??
          document.querySelector('main') ??
          document.body;
      if (contentEl != null) {
        // Try srcset first
        for (final img in contentEl.querySelectorAll('img')) {
          final srcset = img.attributes['srcset'] ?? '';
          final candidate = _extract768wFromSrcset(srcset);
          if (candidate != null) { detailImageUrl = candidate; break; }
        }
        // Fall back to src
        if (detailImageUrl == null || !_isRealEventPhoto(detailImageUrl)) {
          for (final img in contentEl.querySelectorAll('img')) {
            final src = img.attributes['src'] ?? img.attributes['data-src'] ?? '';
            if (_isRealEventPhoto(src)) { detailImageUrl = _thumbnailUrl(src); break; }
          }
        }
      }
    }

    final d = (detailDate?.isNotEmpty == true) ? detailDate! : event.date;
    final t = detailTime ?? event.time;
    final fullDateTime = d.isNotEmpty ? (t != null ? '$d · $t' : d) : null;

    final resolvedLocation = (locationDetails?.isNotEmpty == true)
        ? locationDetails
        : (event.venue.isNotEmpty ? event.venue : null);

    // ── 4. Organizer ──
    String? organizer;
    final allEls = document.querySelectorAll('h2, h3, h4, p, span, div');
    for (int i = 0; i < allEls.length; i++) {
      final text = allEls[i].text.trim().toLowerCase();
      if (text.contains('information about the organizer') ||
          text.contains('about the organizer')) {
        if (i + 1 < allEls.length) {
          final candidate = allEls[i + 1].text.trim();
          if (candidate.isNotEmpty && candidate.length < 120) {
            organizer = candidate;
          }
        }
        break;
      }
    }

    // ── 5. Description paragraphs ──
    final about = <ContentBlock>[];
    final seenTexts = <String>{};
    final contentEl = document.querySelector('article') ??
        document.querySelector('.entry-content') ??
        document.querySelector('.post-content') ??
        document.querySelector('main') ??
        document.body;

    if (contentEl != null) {
      for (final p in contentEl.querySelectorAll('p')) {
        final text = _cleanText(p.text);
        if (text.length < 25) continue;
        if (_looksLikeMetadata(text)) continue;
        if (_isNuFooterText(text)) break;
        if (!seenTexts.add(text)) continue;

        final anchor = p.querySelector('a[href]');
        if (anchor != null) {
          final linkText = anchor.text.trim();
          final href = anchor.attributes['href'] ?? '';
          if (p.text.trim() == linkText && href.isNotEmpty) {
            if (_isMeaningfulLink(linkText, href)) {
              about.add(LinkTextBlock(text: linkText, url: href));
            }
            continue;
          }
        }
        about.add(TextBlock(text));
        if (about.length >= 10) break;
      }
    }

    return NuEventDetails(
      title: title,
      date: event.date,
      venue: event.venue,
      organizer: organizer,
      imageUrl: detailImageUrl,
      fullDateTime: fullDateTime,
      locationDetails: resolvedLocation,
      about: about,
      category: event.category,
      audience: detailAudience ?? event.audience,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERIC ICON TEXT (grandparent approach for older page layouts)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Finds an icon image matching [patterns] and returns the text from its
  /// grandparent element (the row div), which includes the sibling text span.
  String? _iconTextFromGrandparent(dom.Element container, List<String> patterns) {
    for (final img in container.querySelectorAll('img')) {
      final src = (img.attributes['src'] ?? '').toLowerCase();
      final alt = (img.attributes['alt'] ?? '').toLowerCase();
      // Skip filename-based icons when they're used as thumbnails
      if (_isIconFilename(src) && img.parent?.localName != 'span') continue;

      for (final pattern in patterns) {
        if (src.contains(pattern) || alt.contains(pattern)) {
          // Try parent text first (old layout: <span><img> text</span>)
          final parentText = img.parent?.text.trim() ?? '';
          if (parentText.isNotEmpty) return parentText;
          // New layout: <div class="row"><span class="icon"><img></span><span>text</span></div>
          final grandparentText = img.parent?.parent?.text.trim() ?? '';
          if (grandparentText.isNotEmpty) return grandparentText;
        }
      }
    }
    return null;
  }

  bool _isIconFilename(String src) {
    final filename = src.split('/').last.toLowerCase();
    return filename.startsWith('ic-') || filename.startsWith('icon-');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE FILTERING
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isPastEvent(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      final parsed = _parseEventDate(dateStr);
      if (parsed == null) return false;
      return parsed.isBefore(todayMidnight);
    } catch (_) {
      return false;
    }
  }

  DateTime? _parseEventDate(String raw) {
    var cleaned = raw.replaceFirst(RegExp(r'^[A-Za-z]{3},?\s*'), '').trim();
    cleaned = cleaned.replaceFirst(RegExp(r'-\d+'), '');

    for (final fmt in ['MMM dd, yyyy', 'MMM d, yyyy', 'MMM dd yyyy', 'MMM d yyyy']) {
      try { return DateFormat(fmt, 'en_US').parseStrict(cleaned); } catch (_) {}
    }
    for (final fmt in ['MMM dd', 'MMM d']) {
      try {
        final d = DateFormat(fmt, 'en_US').parseStrict(cleaned);
        return DateTime(DateTime.now().year, d.month, d.day);
      } catch (_) {}
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LINK FILTERING
  // ═══════════════════════════════════════════════════════════════════════════

  static const _noiseWords = [
    'register', 'sign up', 'share', 'other events', 'learn more', 'read more',
    'rent a venue', 'full view', 'grid view', 'list view', 'calendar view',
    'skip to', 'back to', 'all events',
  ];

  static const _noiseDomains = [
    'instagram.com', 'facebook.com', 'twitter.com', 'linkedin.com',
    'youtube.com', 'tiktok.com', 'telegram.me', 't.me',
  ];

  bool _isMeaningfulLink(String text, String href) {
    final lower = text.toLowerCase();
    for (final noise in _noiseWords) {
      if (lower.contains(noise)) return false;
    }
    final lowerHref = href.toLowerCase();
    for (final domain in _noiseDomains) {
      if (lowerHref.contains(domain)) return false;
    }
    if (lowerHref.contains('nu.edu.kz') && !lowerHref.contains('/eventsm/')) {
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT / URL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _cleanText(String raw) => raw
      .replaceAll(RegExp(r'[ ​  ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _looksLikeMetadata(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('language:') ||
        lower.startsWith('organizer:') ||
        lower.contains('information about the organizer') ||
        RegExp(r'^\w{3},\s+\w{3}\s').hasMatch(text) ||
        RegExp(r'^\d{2}:\d{2}').hasMatch(text);
  }

  bool _isNuFooterText(String text) {
    final lower = text.toLowerCase();
    return lower.contains('republic of kazakhstan') ||
        lower.contains('kabanbay batyr') ||
        lower.contains('astana city') ||
        lower.contains('© nazarbayev') ||
        lower.contains('nu@nu.edu.kz') ||
        lower.contains('campus map') ||
        lower.contains('commercial services') ||
        lower.contains('quick links') ||
        lower.contains('research portal') ||
        lower.contains('student portal') ||
        lower.contains('institutional repository') ||
        lower.contains('top 23%');
  }

  String? _resolveUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$_baseUrl$raw';
    return '$_baseUrl/$raw';
  }

  String? _thumbnailUrl(String? src) {
    if (src == null || src.isEmpty) return null;
    return src.replaceAll('-1024x576.', '-768x432.');
  }
}
