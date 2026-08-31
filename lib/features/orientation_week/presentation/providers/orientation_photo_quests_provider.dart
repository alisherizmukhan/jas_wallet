import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/orientation_catalog.dart' show kPhotoQuestBonusTokens;
import '../../domain/entities/orientation_results.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

/// UI state for the Photo Quest tab.
///
/// Progress is derived from the mission list rather than stored, so the
/// progress card can never disagree with the grid below it.
class PhotoQuestState {
  const PhotoQuestState({
    required this.missions,
    required this.isLoading,
    required this.submittingMissionId,
    this.bonusTokens = kPhotoQuestBonusTokens,
    this.error,
  });

  const PhotoQuestState.initial()
      : missions = const [],
        isLoading = true,
        submittingMissionId = null,
        bonusTokens = kPhotoQuestBonusTokens,
        error = null;

  final List<PhotoMission> missions;
  final bool isLoading;

  /// Non-null while a submission is in flight — lets that single card show a
  /// spinner instead of blocking the whole grid.
  final String? submittingMissionId;

  /// The one-time "finish every mission" bonus, as the backend actually has
  /// it configured — [kPhotoQuestBonusTokens] only stands in before the
  /// first load lands (or on the local mock, which has no live figure).
  final int bonusTokens;
  final Object? error;

  /// True while any mission is waiting on CV or a moderator — the signal the
  /// background watcher uses to decide whether polling is worth doing at all.
  bool get hasPendingReview => missions.any((m) => m.isPending);

  PhotoQuestProgress get progress => PhotoQuestProgress(
        completedCount: missions.where((m) => m.isCompleted).length,
        totalCount: missions.length,
        bonusTokens: bonusTokens,
      );

  /// Missions matching [difficulty], or all of them when it is null.
  /// Missions for the selected difficulty, with anything still open first and
  /// finished ones pushed to the bottom.
  ///
  /// A completed card already recedes visually, but leaving it in place still
  /// costs the student scrolling past work they've done to find work they
  /// haven't. The sort is stable — `List.sort` isn't, so this partitions
  /// instead — so the authored mission order is preserved inside each group.
  List<PhotoMission> filtered(MissionDifficulty? difficulty) {
    final matching = difficulty == null
        ? missions
        : missions.where((m) => m.difficulty == difficulty);

    final open = <PhotoMission>[];
    final done = <PhotoMission>[];
    for (final mission in matching) {
      (mission.status == MissionStatus.completed ? done : open).add(mission);
    }
    return [...open, ...done];
  }

  PhotoQuestState copyWith({
    List<PhotoMission>? missions,
    bool? isLoading,
    String? submittingMissionId,
    bool clearSubmitting = false,
    int? bonusTokens,
    Object? error,
    bool clearError = false,
  }) {
    return PhotoQuestState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
      submittingMissionId:
          clearSubmitting ? null : (submittingMissionId ?? this.submittingMissionId),
      bonusTokens: bonusTokens ?? this.bonusTokens,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PhotoQuestNotifier extends StateNotifier<PhotoQuestState> {
  PhotoQuestNotifier(this._repo) : super(const PhotoQuestState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  /// Overlay a Club Fair photo mission that does not live on the OW board.
  void upsert(PhotoMission mission) {
    final list = [...state.missions];
    final index = list.indexWhere((m) => m.id == mission.id);
    if (index >= 0) {
      list[index] = mission;
    } else {
      list.add(mission);
    }
    state = state.copyWith(missions: list, isLoading: false);
  }

  List<PhotoMission> _keepClubFair(List<PhotoMission> previous, List<PhotoMission> board) {
    final byId = {for (final m in board) m.id: m};
    for (final m in previous) {
      if (m.id.startsWith('cf_')) byId.putIfAbsent(m.id, () => m);
    }
    return byId.values.toList();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final board = await _repo.getPhotoQuestBoard();
      state = state.copyWith(
        missions: _keepClubFair(state.missions, board.missions),
        bonusTokens: board.bonusTokens,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Refetches without flipping [PhotoQuestState.isLoading] or clearing the
  /// grid, so a poll that lands while the student is reading the page does not
  /// flash a skeleton at them. Failures are swallowed: a dropped poll is not
  /// worth an error state over content that is already on screen.
  ///
  /// Skipped entirely while a submission is in flight — that request will
  /// refresh the list itself, and racing it could overwrite the newer result
  /// with a staler read.
  Future<void> refreshSilently() async {
    if (state.submittingMissionId != null) return;
    try {
      final board = await _repo.getPhotoQuestBoard();
      state = state.copyWith(
        missions: _keepClubFair(state.missions, board.missions),
        bonusTokens: board.bonusTokens,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {}
  }

  /// Submits [localFilePath] for [missionId] and reloads. Returns the raw
  /// result so the page can decide when to celebrate.
  Future<PhotoMissionSubmitResult> submit(String missionId, String localFilePath) =>
      _mutate(missionId, () => _repo.submitMissionPhoto(missionId, localFilePath));

  /// Removes the mission's photo and reloads. The repository takes back what
  /// the submission paid, so the balance stays truthful.
  Future<PhotoMissionSubmitResult> deletePhoto(String missionId) =>
      _mutate(missionId, () => _repo.deleteMissionPhoto(missionId));

  Future<PhotoMissionSubmitResult> _mutate(
    String missionId,
    Future<PhotoMissionSubmitResult> Function() action,
  ) async {
    if (state.submittingMissionId != null) {
      return PhotoMissionSubmitResult.error('Another photo is already uploading.');
    }
    state = state.copyWith(submittingMissionId: missionId, clearError: true);
    final result = await action();
    if (result.isSuccess) {
      final board = await _repo.getPhotoQuestBoard();
      var merged = _keepClubFair(state.missions, board.missions);
      if (result.mission != null) {
        final updated = result.mission!;
        final i = merged.indexWhere((m) => m.id == updated.id);
        if (i >= 0) {
          merged = [...merged]..[i] = updated;
        } else {
          merged = [...merged, updated];
        }
      }
      state = state.copyWith(
        missions: merged,
        bonusTokens: board.bonusTokens,
        clearSubmitting: true,
      );
    } else {
      state = state.copyWith(clearSubmitting: true, error: result.errorMessage);
    }
    return result;
  }
}

final orientationPhotoQuestsProvider =
    StateNotifierProvider<PhotoQuestNotifier, PhotoQuestState>(
  (ref) => PhotoQuestNotifier(ref.read(orientationRepositoryProvider)),
);
