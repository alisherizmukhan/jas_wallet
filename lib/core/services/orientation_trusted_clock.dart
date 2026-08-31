import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// A clock that cannot be wound backward by changing the device's date/time
/// — used to decide when Orientation Week locks for good.
///
/// [DateTime.now()] is whatever the device's clock says, and a student can
/// set that to anything. This tracks the *latest* time ever genuinely
/// observed — either the device clock (only when it's moving forward) or a
/// server's `Date` response header (see [reportServerDateHeader], fed by
/// [ApiClient] on every response and by [primeFromServer] at launch) — and
/// never reports a time earlier than that high-water mark. Rewinding the
/// device clock back past a date Orientation Week already closed on does
/// nothing: [now] keeps returning the latest time this app has actually
/// seen, persisted across restarts.
///
/// Call [init] once at startup (after `SharedPreferences.getInstance()`),
/// same pattern as [TutorialService].
class OrientationTrustedClock {
  OrientationTrustedClock._();
  static final OrientationTrustedClock instance = OrientationTrustedClock._();

  static const _key = 'orientation_clock_high_water_mark_ms';

  SharedPreferences? _prefs;
  DateTime _highWaterMark = DateTime.utc(2020);

  void init(SharedPreferences prefs) {
    _prefs = prefs;
    final storedMs = prefs.getInt(_key);
    if (storedMs != null) {
      _highWaterMark = DateTime.fromMillisecondsSinceEpoch(storedMs, isUtc: true);
    }
    // The device clock is the only signal available before any network
    // response has landed — trust it as a starting point, same as any other
    // app would on a fresh install. A rewound clock self-corrects the moment
    // a real server response arrives (see [reportServerDateHeader]).
    _advance(DateTime.now().toUtc());
  }

  /// The current trusted time, in UTC. Never earlier than the last genuinely
  /// observed time, regardless of what the device clock says right now.
  DateTime now() {
    _advance(DateTime.now().toUtc());
    return _highWaterMark;
  }

  /// Feeds a server-reported time (e.g. an HTTP response's `Date` header,
  /// already parsed) into the ratchet. Authoritative — always wins over the
  /// device clock.
  void reportServerTime(DateTime serverTimeUtc) => _advance(serverTimeUtc);

  /// Parses a raw HTTP `Date` response header — RFC 7231 (`HttpDate`, e.g.
  /// `Tue, 15 Nov 1994 08:12:31 GMT`), falling back to ISO 8601 in case a
  /// proxy rewrites it — and feeds it in if valid. Shared by [ApiClient]'s
  /// interceptor (every response) and [primeFromServer] (one dedicated
  /// request fired at launch), so both stay in sync on what counts as a
  /// trustworthy date.
  void reportServerDateHeader(String? raw) {
    if (raw == null) return;
    final parsed = _tryParseHttpDate(raw) ?? DateTime.tryParse(raw);
    if (parsed != null) reportServerTime(parsed.toUtc());
  }

  static DateTime? _tryParseHttpDate(String raw) {
    try {
      return HttpDate.parse(raw);
    } catch (_) {
      return null;
    }
  }

  void _advance(DateTime candidateUtc) {
    if (candidateUtc.isAfter(_highWaterMark)) {
      _highWaterMark = candidateUtc;
      _prefs?.setInt(_key, candidateUtc.millisecondsSinceEpoch);
    }
  }

  /// Fires one bare, unauthenticated request at the backend's base URL,
  /// purely to read its `Date` response header — the earliest possible
  /// real-world time signal, ahead of whatever the first *business* API
  /// call happens to be (login, wallet, hub content, …). Closes the one gap
  /// [now] otherwise has: a fresh install with the device clock already
  /// wound back, checked before any other response has landed.
  ///
  /// Call once at startup, after [init] (so a persisted high-water mark is
  /// already loaded and this can only move it forward, never overwrite it
  /// with a stale value — see the ordering note in `main.dart`).
  ///
  /// Best-effort and silent: any status code still carries a `Date` header,
  /// and a slow/offline network just means [now] keeps relying on the
  /// device clock a little longer, exactly as before this existed. Never
  /// awaited by a caller that needs to not block startup.
  Future<void> primeFromServer() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          // Any response is useful here — even a 404 carries a Date header.
          validateStatus: (_) => true,
        ),
      );
      final response = await dio.head<void>(ApiConfig.baseUrl);
      reportServerDateHeader(response.headers.value('date'));
    } catch (_) {
      // Offline, timed out, whatever — not an error for this purpose.
    }
  }
}
