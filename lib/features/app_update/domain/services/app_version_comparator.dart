import 'package:pub_semver/pub_semver.dart';

/// Semantic-version parsing and comparison. All comparisons go through
/// [pub_semver]'s [Version] type — never a manual string/split comparison,
/// which breaks on '2.10.0' vs '2.9.0' (string-sorts '2.10.0' as smaller).
abstract class AppVersionComparator {
  /// Parses a version string from Remote Config or [PackageInfo.version].
  ///
  /// Tolerant of common real-world formats this app/Remote Config may emit:
  ///   '1.2.3'        -> 1.2.3
  ///   '1.2'           -> 1.2.0   (missing patch)
  ///   '1'             -> 1.0.0   (missing minor+patch)
  ///   '1.2.3+8'       -> 1.2.3   (build number, e.g. from PackageInfo.version
  ///                                on platforms that append it — stripped)
  ///   '1.2.3-beta.1'  -> 1.2.3-beta.1 (pre-release, compares below 1.2.3)
  ///
  /// Returns null on anything unparseable (empty string, garbage input) —
  /// callers must treat null as "no version pressure", never crash.
  static Version? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Normalize 'X' or 'X.Y' to full 'X.Y.Z' — Version.parse requires all
    // three components.
    final buildSplit = trimmed.split('+');
    final core = buildSplit.first;
    final preReleaseSplit = core.split('-');
    final numericPart = preReleaseSplit.first;
    final preRelease =
        preReleaseSplit.length > 1 ? preReleaseSplit.sublist(1).join('-') : null;

    final parts = numericPart.split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    if (parts.any((p) => int.tryParse(p) == null)) return null;

    final padded = [...parts, '0', '0'].take(3).join('.');
    final normalized = preRelease != null ? '$padded-$preRelease' : padded;

    try {
      return Version.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// True when [current] is strictly below [target]. A null [target]
  /// (unparseable/unset Remote Config value) always returns false — an
  /// absent or malformed threshold must never itself trigger an update.
  static bool isBelow(Version current, Version? target) {
    if (target == null) return false;
    return current < target;
  }
}
