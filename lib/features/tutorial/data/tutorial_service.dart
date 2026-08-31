import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which tutorial stories have been seen.
///
/// Call [init] once at startup (after SharedPreferences is available).
/// After that, [shouldShowSync] and [markSeenSync] are synchronous so that
/// tutorial overlays can be pushed on the very first frame with no async gap.
class TutorialService {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  static const _prefix = 'tutorial_seen_';

  SharedPreferences? _prefs;
  final _seen = <String>{};

  /// Call once in main() after SharedPreferences.getInstance().
  void init(SharedPreferences prefs) {
    _prefs = prefs;
    _seen.clear();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        _seen.add(key.substring(_prefix.length));
      }
    }
  }

  /// Returns true if this tutorial has not been shown yet.
  /// Always synchronous after [init].
  bool shouldShowSync(String tutorialId) => !_seen.contains(tutorialId);

  /// Marks tutorial as seen immediately (in-memory + persists async).
  void markSeenSync(String tutorialId) {
    _seen.add(tutorialId);
    _prefs?.setBool('$_prefix$tutorialId', true);
  }

  /// Resets all tutorials — useful for testing or account switch.
  Future<void> resetAll() async {
    _seen.clear();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
