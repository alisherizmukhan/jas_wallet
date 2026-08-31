/// Shared SALTO digital-key lifecycle constants.
///
/// [keyTtl] and [baseEarlyRefreshThreshold] are the single source of truth
/// for both `SaltoKeyManager` (prewarm-time refresh decision) and
/// `SaltoRepositoryImpl` (persisted-cache-hit background refresh) — kept in
/// one place so the two independently-implemented refresh triggers can
/// never silently drift out of sync with each other.
class SaltoKeyRefreshPolicy {
  SaltoKeyRefreshPolicy._();

  static const keyTtl = Duration(days: 7);
  static const baseEarlyRefreshThreshold = Duration(days: 2);

  /// Max magnitude of the per-device jitter applied on top of
  /// [baseEarlyRefreshThreshold] by [jitterFor].
  static const maxJitter = Duration(hours: 12);

  /// Deterministic jitter in `[-maxJitter, +maxJitter]` derived from [seed]
  /// (the device's SALTO mobile-phone-ID) — stable across app launches for
  /// a given install, but different device-to-device.
  ///
  /// Spreads the background-refresh trigger across a cohort of devices
  /// whose keys were issued around the same time (mass onboarding, a
  /// backend key rotation) instead of every device crossing the refresh
  /// threshold in the same instant and stampeding the SALTO backend.
  static Duration jitterFor(String seed) {
    if (seed.isEmpty) return Duration.zero;
    final hash = seed.codeUnits.fold<int>(
      0,
      (acc, c) => (acc * 31 + c) & 0x7fffffff,
    );
    final fraction = (hash % 1000) / 1000.0; // deterministic, 0.0 .. 0.999
    final offsetMs = ((fraction * 2 - 1) * maxJitter.inMilliseconds).round();
    return Duration(milliseconds: offsetMs);
  }
}
