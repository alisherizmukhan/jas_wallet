import 'dart:math';

import 'package:flutter/material.dart';

/// Meal attendance streak data.
///
/// Rules:
///   received meal   → streak increments
///   honest cancel   → streak is preserved (no increment, no reset)
///   no-show         → streak resets to 0
@immutable
class MealStreak {
  const MealStreak({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalReceived,
    required this.totalCancelled,
    required this.totalNoShows,
    this.lastActivityDate,
  });

  /// Consecutive streak days (days where at least one meal was received).
  final int currentStreak;

  /// All-time best streak.
  final int bestStreak;

  final int totalReceived;
  final int totalCancelled;
  final int totalNoShows;

  /// Date of the most recent received meal.
  final DateTime? lastActivityDate;

  // ─── Milestones ──────────────────────────────────────────────────────────────

  static const List<int> milestones = [3, 7, 14, 21, 30, 60, 100];

  /// The next milestone the student hasn't yet reached.
  int? get nextMilestone {
    for (final m in milestones) {
      if (currentStreak < m) return m;
    }
    return null;
  }

  /// Days remaining until [nextMilestone].
  int? get daysToNextMilestone {
    final next = nextMilestone;
    return next != null ? next - currentStreak : null;
  }

  /// XP bonus awarded when a streak milestone is reached.
  static int xpForMilestone(int streakDays) => switch (streakDays) {
        3 => 20,
        7 => 50,
        14 => 100,
        21 => 150,
        30 => 200,
        60 => 400,
        100 => 800,
        _ => 0,
      };

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  MealStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    int? totalReceived,
    int? totalCancelled,
    int? totalNoShows,
    DateTime? lastActivityDate,
  }) =>
      MealStreak(
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: max(bestStreak ?? this.bestStreak,
            currentStreak ?? this.currentStreak),
        totalReceived: totalReceived ?? this.totalReceived,
        totalCancelled: totalCancelled ?? this.totalCancelled,
        totalNoShows: totalNoShows ?? this.totalNoShows,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      );

  static const MealStreak zero = MealStreak(
    currentStreak: 0,
    bestStreak: 0,
    totalReceived: 0,
    totalCancelled: 0,
    totalNoShows: 0,
  );
}
