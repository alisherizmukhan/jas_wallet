import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/orientation_progress.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

class OrientationProgressState {
  const OrientationProgressState({required this.progress, required this.isLoading, this.error});

  const OrientationProgressState.initial()
      : progress = null,
        isLoading = true,
        error = null;

  final OrientationProgress? progress;
  final bool isLoading;
  final Object? error;

  OrientationProgressState copyWith({
    OrientationProgress? progress,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return OrientationProgressState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrientationProgressNotifier extends StateNotifier<OrientationProgressState> {
  OrientationProgressNotifier(this._repo) : super(const OrientationProgressState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final progress = await _repo.getProgress();
      state = state.copyWith(progress: progress, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

final orientationProgressProvider =
    StateNotifierProvider<OrientationProgressNotifier, OrientationProgressState>(
  (ref) => OrientationProgressNotifier(ref.read(orientationRepositoryProvider)),
);
