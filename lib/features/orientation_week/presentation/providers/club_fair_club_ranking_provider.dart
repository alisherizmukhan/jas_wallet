import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/club_fair_club_rank.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

class ClubFairClubRankingState {
  const ClubFairClubRankingState({
    required this.ranking,
    required this.isLoading,
    this.error,
  });

  const ClubFairClubRankingState.initial()
      : ranking = null,
        isLoading = true,
        error = null;

  final ClubFairClubRanking? ranking;
  final bool isLoading;
  final Object? error;

  bool get hasData => ranking != null;

  ClubFairClubRankingState copyWith({
    ClubFairClubRanking? ranking,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return ClubFairClubRankingState(
      ranking: ranking ?? this.ranking,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClubFairClubRankingNotifier extends StateNotifier<ClubFairClubRankingState> {
  ClubFairClubRankingNotifier(this._repo) : super(const ClubFairClubRankingState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ranking = await _repo.getClubRanking();
      state = state.copyWith(ranking: ranking, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final clubFairClubRankingProvider =
    StateNotifierProvider.autoDispose<ClubFairClubRankingNotifier, ClubFairClubRankingState>(
  (ref) => ClubFairClubRankingNotifier(ref.read(orientationRepositoryProvider)),
);
