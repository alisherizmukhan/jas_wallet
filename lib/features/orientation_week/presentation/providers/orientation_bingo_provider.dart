import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/orientation_results.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

/// UI state for the Bingo board.
///
/// All board maths (line detection, progress) lives on [BingoBoard] itself
/// and all payout rules live in the repository, so this notifier only
/// coordinates loading and the in-flight tile.
class BingoState {
  const BingoState({
    required this.board,
    required this.isLoading,
    required this.processingTileId,
    this.error,
  });

  const BingoState.initial()
      : board = null,
        isLoading = true,
        processingTileId = null,
        error = null;

  final BingoBoard? board;
  final bool isLoading;

  /// Non-null while a tile completion is in flight — lets that single tile
  /// show a spinner instead of blocking the whole board.
  final String? processingTileId;
  final Object? error;

  BingoProgress? get progress => board?.progress;

  BingoState copyWith({
    BingoBoard? board,
    bool? isLoading,
    String? processingTileId,
    bool clearProcessing = false,
    Object? error,
    bool clearError = false,
  }) {
    return BingoState(
      board: board ?? this.board,
      isLoading: isLoading ?? this.isLoading,
      processingTileId: clearProcessing ? null : (processingTileId ?? this.processingTileId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BingoNotifier extends StateNotifier<BingoState> {
  BingoNotifier(this._repo) : super(const BingoState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final board = await _repo.getBingoBoard();
      state = state.copyWith(board: board, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Completes a tile and reloads the board. Returns the raw result so the
  /// page can decide when to celebrate a newly completed line or the board.
  Future<BingoTileResult> completeTile(String tileId) async {
    if (state.processingTileId != null) {
      return BingoTileResult.error('Another tile is already being completed.');
    }
    state = state.copyWith(processingTileId: tileId, clearError: true);
    final result = await _repo.completeBingoTile(tileId);
    if (result.isSuccess) {
      final board = await _repo.getBingoBoard();
      state = state.copyWith(board: board, clearProcessing: true);
    } else {
      state = state.copyWith(clearProcessing: true, error: result.errorMessage);
    }
    return result;
  }
}

final orientationBingoProvider = StateNotifierProvider<BingoNotifier, BingoState>(
  (ref) => BingoNotifier(ref.read(orientationRepositoryProvider)),
);
