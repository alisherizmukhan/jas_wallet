import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/meal_confirmation.dart';
import 'social_meal_repository_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class SVCConfirmationState {
  /// The current user's saved confirmation for tomorrow (null if not yet saved).
  final MealConfirmation? myConfirmation;

  final bool isLoaded;
  final bool isSaving;
  final bool isMember;
  final DateTime? targetMealDate;
  final bool isConfirmationClosed;
  final DateTime? confirmationCutoffAt;

  List<MealConfirmation> get allConfirmations =>
      myConfirmation == null ? const [] : [myConfirmation!];

  const SVCConfirmationState({
    this.myConfirmation,
    this.isLoaded = false,
    this.isSaving = false,
    this.isMember = false,
    this.targetMealDate,
    this.isConfirmationClosed = false,
    this.confirmationCutoffAt,
  });

  SVCConfirmationState copyWith({
    MealConfirmation? myConfirmation,
    bool clearMyConfirmation = false,
    bool? isLoaded,
    bool? isSaving,
    bool? isMember,
    DateTime? targetMealDate,
    bool? isConfirmationClosed,
    DateTime? confirmationCutoffAt,
  }) {
    return SVCConfirmationState(
      myConfirmation:
          clearMyConfirmation ? null : myConfirmation ?? this.myConfirmation,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      isMember: isMember ?? this.isMember,
      targetMealDate: targetMealDate ?? this.targetMealDate,
      isConfirmationClosed: isConfirmationClosed ?? this.isConfirmationClosed,
      confirmationCutoffAt: confirmationCutoffAt ?? this.confirmationCutoffAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class SVCConfirmationNotifier extends StateNotifier<SVCConfirmationState> {
  SVCConfirmationNotifier(this._ref) : super(const SVCConfirmationState()) {
    _loadState();
  }

  final Ref _ref;

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> loadState() => _loadState();

  Future<void> _loadState() async {
    try {
      final status = await _ref.read(socialMealRepositoryProvider).getStatus();

      state = SVCConfirmationState(
        myConfirmation: status.tomorrowConfirmation,
        isLoaded: true,
        isMember: status.isMember,
        targetMealDate: status.targetMealDate,
        isConfirmationClosed: status.confirmationClosed,
        confirmationCutoffAt: status.confirmationCutoffAt,
      );
    } catch (e) {
      state = const SVCConfirmationState(
        isLoaded: true,
      );
    }
  }

  /// Saves the current user's meal confirmation for tomorrow.
  Future<void> saveConfirmation({
    required bool breakfast,
    required bool lunch,
    required bool dinner,
  }) async {
    state = state.copyWith(isSaving: true);

    try {
      final conf =
          await _ref.read(socialMealRepositoryProvider).saveTomorrowDeclaration(
                breakfast: breakfast,
                lunch: lunch,
                dinner: dinner,
              );

      state = state.copyWith(
        myConfirmation: conf,
        isSaving: false,
        targetMealDate: conf.date,
        isConfirmationClosed: false,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final svcConfirmationProvider =
    StateNotifierProvider<SVCConfirmationNotifier, SVCConfirmationState>(
  (ref) => SVCConfirmationNotifier(ref),
);
