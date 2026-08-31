import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_completion_provider.dart';

/// Holds which profile sections are currently highlighted.
/// Triggered when the user taps the completion card;
/// auto-clears after [_kHighlightDuration].
class SectionHighlightNotifier extends StateNotifier<Set<ProfileSection>> {
  SectionHighlightNotifier() : super(const {});

  static const _kHighlightDuration = Duration(seconds: 5);
  Timer? _clearTimer;

  /// Activates highlight for [sections] and starts the auto-clear timer.
  void trigger(Set<ProfileSection> sections) {
    _clearTimer?.cancel();
    state = Set.unmodifiable(sections);
    _clearTimer = Timer(_kHighlightDuration, clear);
  }

  /// Clears all active highlights immediately.
  void clear() {
    _clearTimer?.cancel();
    _clearTimer = null;
    state = const {};
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }
}

final sectionHighlightProvider =
    StateNotifierProvider<SectionHighlightNotifier, Set<ProfileSection>>(
  (ref) => SectionHighlightNotifier(),
);
