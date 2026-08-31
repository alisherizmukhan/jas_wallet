import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the "About Orientation Week" intro card is collapsed.
///
/// The intro is expanded on first open (default `false` = open) and can be
/// collapsed like an FAQ row — it never disappears, only folds to its header.
/// The open/closed choice persists across sessions via SharedPreferences.
class OrientationAboutNotifier extends StateNotifier<bool> {
  OrientationAboutNotifier() : super(false) {
    _load();
  }

  static const _key = 'orientation_about_collapsed';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// `true` once the intro card has been collapsed to its header.
final orientationAboutCollapsedProvider =
    StateNotifierProvider<OrientationAboutNotifier, bool>((ref) => OrientationAboutNotifier());
