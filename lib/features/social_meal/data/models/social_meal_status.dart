import '../../domain/entities/meal_confirmation.dart';

class SocialMealStatus {
  const SocialMealStatus({
    required this.isMember,
    this.targetMealDate,
    required this.confirmationClosed,
    this.confirmationCutoffAt,
    required this.todayMealsUsed,
    required this.remainingMealsToday,
    this.tomorrowConfirmation,
  });

  final bool isMember;
  final DateTime? targetMealDate;
  final bool confirmationClosed;
  final DateTime? confirmationCutoffAt;
  final int todayMealsUsed;
  final int remainingMealsToday;
  final MealConfirmation? tomorrowConfirmation;

  factory SocialMealStatus.fromJson(Map<String, dynamic> json) {
    final confirmation = json['tomorrow_declaration'] as Map<String, dynamic>?;
    final targetDate = json['target_meal_date'] as String?;
    final cutoffAt = json['confirmation_cutoff_at'] as String?;
    final mealDate = confirmation?['meal_date'] as String?;
    return SocialMealStatus(
      isMember: json['is_member'] as bool? ?? false,
      targetMealDate: targetDate != null ? DateTime.parse(targetDate) : null,
      confirmationClosed: json['confirmation_closed'] as bool? ?? false,
      confirmationCutoffAt: cutoffAt != null ? DateTime.parse(cutoffAt) : null,
      todayMealsUsed: json['today_redemptions_count'] as int? ?? 0,
      remainingMealsToday: json['remaining_redemptions_today'] as int? ?? 0,
      tomorrowConfirmation: confirmation == null || mealDate == null
          ? null
          : MealConfirmation(
              studentId: 'current_user',
              date: DateTime.parse(mealDate),
              breakfast: confirmation['wants_breakfast'] as bool? ?? false,
              lunch: confirmation['wants_lunch'] as bool? ?? false,
              dinner: confirmation['wants_dinner'] as bool? ?? false,
            ),
    );
  }
}
