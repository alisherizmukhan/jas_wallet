import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/orientation_challenge.dart';
import '../../domain/entities/orientation_identity.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

class ChallengesState {
  const ChallengesState({
    required this.challenges,
    required this.isLoading,
    this.error,
    this.busyChallengeId,
  });

  const ChallengesState.initial()
      : challenges = const [],
        isLoading = true,
        error = null,
        busyChallengeId = null;

  final List<OrientationChallenge> challenges;
  final bool isLoading;
  final Object? error;

  /// The challenge whose save/scan is in flight — one at a time, so the sheet
  /// can disable its own button without every row spinning.
  final String? busyChallengeId;

  bool get hasData => challenges.isNotEmpty;

  ChallengeProgress get progress => ChallengeProgress.from(challenges);

  /// Open first: a finished challenge has nothing left to do, and a list that
  /// leads with completed rows buries the point of the page.
  List<OrientationChallenge> get ordered {
    final sorted = [...challenges];
    sorted.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
      return challenges.indexOf(a).compareTo(challenges.indexOf(b));
    });
    return sorted;
  }

  ChallengesState copyWith({
    List<OrientationChallenge>? challenges,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    String? busyChallengeId,
    bool clearBusy = false,
  }) {
    return ChallengesState(
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      busyChallengeId: clearBusy ? null : (busyChallengeId ?? this.busyChallengeId),
    );
  }
}

class ChallengesNotifier extends StateNotifier<ChallengesState> {
  ChallengesNotifier(this._repo) : super(const ChallengesState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        challenges: await _repo.getChallenges(),
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Stores a typed answer. Returns the tokens awarded (0 when the challenge
  /// had already been paid for, which is what editing an answer does).
  Future<int> answer(String challengeId, String value) async {
    state = state.copyWith(busyChallengeId: challengeId);
    try {
      final awarded = await _repo.answerChallenge(challengeId, value);
      await load();
      return awarded;
    } finally {
      state = state.copyWith(clearBusy: true);
    }
  }

  Future<void> clear(String challengeId) async {
    state = state.copyWith(busyChallengeId: challengeId);
    try {
      await _repo.clearChallengeAnswer(challengeId);
      await load();
    } finally {
      state = state.copyWith(clearBusy: true);
    }
  }

  /// Evaluates a scanned payload against the challenge's rule.
  Future<ScanOutcome> submitScan({
    required String challengeId,
    required OrientationIdentity me,
    required String scannedRaw,
  }) async {
    state = state.copyWith(busyChallengeId: challengeId);
    try {
      final outcome = await _repo.submitChallengeScan(
        challengeId: challengeId,
        me: me,
        scannedRaw: scannedRaw,
      );
      // Only a counted scan changes anything worth reloading for.
      if (outcome is ScanAccepted) await load();
      return outcome;
    } finally {
      state = state.copyWith(clearBusy: true);
    }
  }
}

final orientationChallengesProvider =
    StateNotifierProvider<ChallengesNotifier, ChallengesState>(
  (ref) => ChallengesNotifier(ref.watch(orientationRepositoryProvider)),
);

/// One challenge by id, live off state — a detail sheet reads its subject this
/// way rather than holding the entity it was opened with, so saving an answer
/// updates the row behind it.
final challengeByIdProvider = Provider.family<OrientationChallenge?, String>((ref, id) {
  for (final challenge in ref.watch(orientationChallengesProvider).challenges) {
    if (challenge.id == id) return challenge;
  }
  return null;
});
