import 'package:flutter/material.dart';

import 'meal_slot.dart';

/// Status of an individual meal entry under the new default-attendance model.
enum MealStatus {
  scheduled, // Default — student will attend
  cancelled, // Student cancelled before the 24-hour deadline
  received, // Student scanned QR and received the meal
  noShow; // Meal time passed without cancel or QR scan

  String get key => name;

  static MealStatus fromKey(String key) =>
      MealStatus.values.firstWhere((s) => s.key == key,
          orElse: () => MealStatus.scheduled);
}

/// A single meal (breakfast/lunch/dinner) for one specific day.
///
/// Under the new model every student is automatically scheduled for all three
/// meals. The student only acts when NOT attending (cancels). A QR scan at
/// the cafeteria transitions the entry to [MealStatus.received].
@immutable
class MealEntry {
  const MealEntry({
    required this.id,
    required this.date,
    required this.slot,
    required this.status,
    this.cancelledAt,
    this.receivedAt,
  });

  final String id;

  /// Date component only — time is ignored.
  final DateTime date;

  final MealSlot slot;
  final MealStatus status;
  final DateTime? cancelledAt;
  final DateTime? receivedAt;

  // ─── Derived ────────────────────────────────────────────────────────────────

  /// Cancellation must happen at least 24 hours before the meal starts.
  DateTime get cancellationDeadline =>
      slot.startDateTime(date).subtract(const Duration(hours: 24));

  bool get canCancel =>
      status == MealStatus.scheduled &&
      DateTime.now().isBefore(cancellationDeadline);

  /// True when a previously cancelled meal can be restored.
  /// Requires the same 24-hour deadline to still be open.
  bool get canUndoCancel =>
      status == MealStatus.cancelled &&
      DateTime.now().isBefore(cancellationDeadline);

  bool get isDeadlinePassed =>
      DateTime.now().isAfter(cancellationDeadline);

  bool get isPast => DateTime.now().isAfter(slot.endDateTime(date));

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(slot.startDateTime(date)) && now.isBefore(slot.endDateTime(date));
  }

  bool get isFuture => DateTime.now().isBefore(slot.startDateTime(date));

  // ─── Copy ───────────────────────────────────────────────────────────────────

  MealEntry copyWith({
    MealStatus? status,
    DateTime? cancelledAt,
    DateTime? receivedAt,
  }) =>
      MealEntry(
        id: id,
        date: date,
        slot: slot,
        status: status ?? this.status,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        receivedAt: receivedAt ?? this.receivedAt,
      );

  // ─── Factory ─────────────────────────────────────────────────────────────────

  static String makeId(DateTime date, MealSlot slot) {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${d}_${slot.key}';
  }
}
