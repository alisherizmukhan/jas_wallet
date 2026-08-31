import '../../domain/entities/meal_slot.dart';

class SocialMealRedeemResponse {
  const SocialMealRedeemResponse({
    required this.mealDate,
    required this.visitNumber,
    required this.todayMealsUsed,
    required this.remainingMealsToday,
    required this.scannedAt,
  });

  final DateTime mealDate;
  final int visitNumber;
  final int todayMealsUsed;
  final int remainingMealsToday;
  final DateTime scannedAt;

  /// The three daily slots are fixed and always redeemed in order, so
  /// "remaining today" is just what's left after whichever slot this
  /// scan falls in — breakfast leaves 2 (lunch + dinner), lunch leaves 1
  /// (dinner), dinner is the last slot and leaves 0. Falls back to the
  /// backend-reported count if the scan time doesn't land in any slot
  /// window (e.g. before 08:00).
  int get remainingSlotsToday {
    final slot = MealSlot.currentSlot(scannedAt);
    return switch (slot) {
      MealSlot.breakfast => 2,
      MealSlot.lunch => 1,
      MealSlot.dinner => 0,
      null => remainingMealsToday,
    };
  }

  factory SocialMealRedeemResponse.fromJson(Map<String, dynamic> json) {
    return SocialMealRedeemResponse(
      mealDate: DateTime.parse(json['meal_date'] as String),
      visitNumber: json['visit_number'] as int? ?? 0,
      todayMealsUsed: json['today_redemptions_count'] as int? ?? 0,
      remainingMealsToday: json['remaining_redemptions_today'] as int? ?? 0,
      scannedAt: DateTime.parse(json['scanned_at'] as String).toLocal(),
    );
  }
}
