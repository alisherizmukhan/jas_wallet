// ignore_for_file: empty_catches
import 'dart:async';

import '../../../../core/services/auth_storage_service.dart';
import '../../analytics/salto_analytics.dart';
import '../repositories/salto_repository.dart';
import 'salto_key_refresh_policy.dart';

/// A cached SALTO digital key with validity metadata.
class SaltoKey {
  const SaltoKey({
    required this.keyHex,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String keyHex;
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// True while the current time is before [expiresAt].
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// True when fewer than [SaltoKeyRefreshPolicy.baseEarlyRefreshThreshold]
  /// remain before expiry — trigger a refresh now.
  bool get needsRefresh =>
      expiresAt.difference(DateTime.now()) <
      SaltoKeyRefreshPolicy.baseEarlyRefreshThreshold;
}

/// Manages SALTO digital-key lifecycle: local validation, expiry checks, and
/// background refresh so the Access page never has to wait for the network.
///
/// Call [prewarm] after login (or on app start) to ensure the key is
/// already in the repository's in-memory cache when the user opens the
/// Access page.
class SaltoKeyManager {
  SaltoKeyManager({
    required SaltoRepository repository,
    required AuthStorageService authStorage,
  }) : _repository = repository,
       _authStorage = authStorage;

  final SaltoRepository _repository;
  final AuthStorageService _authStorage;

  static const _keyTtl = SaltoKeyRefreshPolicy.keyTtl;
  static const _earlyRefreshThreshold =
      SaltoKeyRefreshPolicy.baseEarlyRefreshThreshold;

  // ── Validation helpers ────────────────────────────────────────────────

  /// Returns true when a key issued at [issuedAt] is still within its TTL.
  bool isKeyValid({required DateTime issuedAt}) =>
      DateTime.now().difference(issuedAt) < _keyTtl;

  /// Returns true when fewer than [_earlyRefreshThreshold] remain before
  /// expiry — the caller should trigger a background refresh.
  bool needsBackgroundRefresh({required DateTime issuedAt}) {
    final expiresAt = issuedAt.add(_keyTtl);
    return expiresAt.difference(DateTime.now()) < _earlyRefreshThreshold;
  }

  // ── Cache access ──────────────────────────────────────────────────────

  /// Reads the persisted key and its timestamp from secure storage.
  /// Returns null when no valid cached key exists.
  Future<SaltoKey?> loadCachedKey() async {
    final keyHex = await _authStorage.getSaltoDigitalKey();
    final storedAt = await _authStorage.getSaltoDigitalKeyStoredAt();
    if (keyHex == null || storedAt == null) return null;
    return SaltoKey(
      keyHex: keyHex,
      issuedAt: storedAt,
      expiresAt: storedAt.add(_keyTtl),
    );
  }

  // ── Startup pre-warm ──────────────────────────────────────────────────

  /// Fire-and-forget: ensures a valid key is in the repository's in-memory
  /// cache so the first unlock attempt is instant.
  ///
  /// - If no key is cached → fetches from the backend.
  /// - If key is expired → force-refreshes from the backend.
  /// - If key is valid but close to expiry → background-refreshes silently.
  /// - If key is fresh → no-op (the repository already has it in memory).
  void prewarm() => unawaited(_doPrewarm());

  Future<void> _doPrewarm() async {
    try {
      final key = await loadCachedKey();
      if (key == null) {
        // Timestamp survives TTL expiry (only the key bytes are deleted).
        // If timestamp exists, the key was expired → backend needs refresh=true
        // to re-issue a fresh SALTO Ship key. Without it the backend returns the
        // same expired key and the native SDK rejects it.
        // If no timestamp, the key was never issued → normal fetch is fine.
        final storedAt = await _authStorage.getSaltoDigitalKeyStoredAt();
        final keyWasExpired =
            storedAt != null &&
            DateTime.now().difference(storedAt) >= _keyTtl;
        await _trackedFetch(forceRefresh: keyWasExpired);
        return;
      }
      if (!key.isValid) {
        await _trackedFetch(forceRefresh: true);
        return;
      }
      if (key.needsRefresh) {
        unawaited(_trackedFetch(forceRefresh: true));
      } else {
        // Prime the repository's in-memory cache from persistent storage —
        // a plain cache read, not a real refresh, so no analytics here.
        unawaited(_repository.getDigitalKey(forceRefresh: false));
      }
    } catch (e) {
    }
  }

  /// Wraps a real (forceRefresh: true) or first-ever key fetch with Key
  /// Refresh Started/Completed/Failed analytics. Never used for the plain
  /// cache-priming read (forceRefresh: false with an already-fresh key) —
  /// that path isn't a meaningful "refresh" event.
  Future<String?> _trackedFetch({required bool forceRefresh}) async {
    SaltoAnalytics.instance.trackKeyRefreshStarted();
    try {
      final key = await _repository.getDigitalKey(forceRefresh: forceRefresh);
      SaltoAnalytics.instance.trackKeyRefreshCompleted();
      if (forceRefresh) SaltoAnalytics.instance.trackDigitalKeyRefreshed();
      return key;
    } catch (e) {
      SaltoAnalytics.instance.trackKeyRefreshFailed(reason: e.toString());
      rethrow;
    }
  }

  /// Force-refresh the digital key from the backend.
  /// Use this when the cached key is known to be stale or rejected.
  Future<String?> refreshKey() => _trackedFetch(forceRefresh: true);
}
