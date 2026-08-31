import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the "In collaboration with ADSL" credit card is collapsed.
///
/// Folded by default — it's a closing credit, not a headline — but opens
/// like an FAQ row to a short "what is ADSL" blurb. Persists across
/// sessions via SharedPreferences, mirroring [orientationAboutCollapsedProvider].
class OrientationPartnerNotifier extends StateNotifier<bool> {
  OrientationPartnerNotifier() : super(true) {
    _load();
  }

  static const _key = 'orientation_partner_collapsed';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// `true` while the partner credit card is folded to just its header.
final orientationPartnerCollapsedProvider =
    StateNotifierProvider<OrientationPartnerNotifier, bool>((ref) => OrientationPartnerNotifier());
