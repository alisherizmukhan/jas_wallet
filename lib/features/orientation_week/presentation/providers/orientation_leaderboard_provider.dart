import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

class OrientationLeaderboardState {
  const OrientationLeaderboardState({
    required this.scope,
    required this.entries,
    required this.isLoading,
    this.error,
  });

  const OrientationLeaderboardState.initial()
      : scope = LeaderboardScope.global,
        entries = const [],
        isLoading = true,
        error = null;

  final LeaderboardScope scope;
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final Object? error;

  OrientationLeaderboardState copyWith({
    LeaderboardScope? scope,
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return OrientationLeaderboardState(
      scope: scope ?? this.scope,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrientationLeaderboardNotifier extends StateNotifier<OrientationLeaderboardState> {
  OrientationLeaderboardNotifier(this._repo, this._ref) : super(const OrientationLeaderboardState.initial()) {
    load();
  }

  final OrientationRepository _repo;
  final Ref _ref;

  Future<void> load({LeaderboardScope? scope}) async {
    final effectiveScope = scope ?? state.scope;
    state = state.copyWith(scope: effectiveScope, isLoading: true, clearError: true);
    try {
      final entries = await _repo.getLeaderboard(scope: effectiveScope);
      state = state.copyWith(entries: _withRealSelf(entries), isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Neither the mock repo nor the live leaderboard API can be trusted for
  /// *this* student's own name/photo — the mock hard-codes a placeholder and
  /// the API's `is_current_user` row is whatever the backend happens to
  /// echo back. The signed-in profile is the one place that's always right,
  /// so the entry flagged `isCurrentUser` is always overwritten with it
  /// rather than trusted as sent.
  List<LeaderboardEntry> _withRealSelf(List<LeaderboardEntry> entries) {
    final me = _ref.read(userProvider).valueOrNull;
    if (me == null) return entries;
    return [
      for (final entry in entries)
        if (entry.isCurrentUser)
          entry.copyWith(
            student: entry.student.copyWith(
              fullName: me.fullName.trim().isEmpty ? entry.student.fullName : me.fullName,
              initials: me.initials.isEmpty ? entry.student.initials : me.initials,
              photoUrl: me.avatarUrl,
            ),
          )
        else
          entry,
    ];
  }

  Future<void> changeScope(LeaderboardScope scope) {
    if (scope == state.scope) return Future.value();
    return load(scope: scope);
  }
}

final orientationLeaderboardProvider =
    StateNotifierProvider<OrientationLeaderboardNotifier, OrientationLeaderboardState>(
  (ref) => OrientationLeaderboardNotifier(ref.read(orientationRepositoryProvider), ref),
);
