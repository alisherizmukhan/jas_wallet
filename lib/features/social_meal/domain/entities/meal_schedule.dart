import 'package:flutter/material.dart';

import 'meal_entry.dart';
import 'meal_slot.dart';

/// The complete meal plan for a single calendar day: breakfast + lunch + dinner.
///
/// Every day always has exactly three [MealEntry] objects, one per [MealSlot].
@immutable
class MealSchedule {
  const MealSchedule({
    required this.date,
    required this.meals,
  });

  /// Calendar date (time component is ignored).
  final DateTime date;

  /// Exactly three entries: breakfast, lunch, dinner.
  final List<MealEntry> meals;

  // ─── Accessors ───────────────────────────────────────────────────────────────

  MealEntry get breakfast =>
      meals.firstWhere((m) => m.slot == MealSlot.breakfast);
  MealEntry get lunch =>
      meals.firstWhere((m) => m.slot == MealSlot.lunch);
  MealEntry get dinner =>
      meals.firstWhere((m) => m.slot == MealSlot.dinner);

  MealEntry entryFor(MealSlot slot) =>
      meals.firstWhere((m) => m.slot == slot);

  // ─── Counts ─────────────────────────────────────────────────────────────────

  int get receivedCount =>
      meals.where((m) => m.status == MealStatus.received).length;
  int get cancelledCount =>
      meals.where((m) => m.status == MealStatus.cancelled).length;
  int get noShowCount =>
      meals.where((m) => m.status == MealStatus.noShow).length;
  int get scheduledCount =>
      meals.where((m) => m.status == MealStatus.scheduled).length;

  // ─── Predicates ─────────────────────────────────────────────────────────────

  bool get hasReceived => receivedCount > 0;
  bool get hasNoShow => noShowCount > 0;

  /// All meals are cancelled (honest planned absence for the whole day).
  bool get allCancelled => cancelledCount == 3;

  /// Every past meal on this day has been settled (no pending scheduled ones).
  bool get isFullySettled =>
      meals.every((m) => m.status != MealStatus.scheduled || !m.isPast);

  // ─── Copy ───────────────────────────────────────────────────────────────────

  MealSchedule copyWithEntry(MealEntry updated) {
    return MealSchedule(
      date: date,
      meals: meals
          .map((m) => m.slot == updated.slot ? updated : m)
          .toList(),
    );
  }
}
