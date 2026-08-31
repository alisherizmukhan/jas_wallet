/// Holds a student's meal selections for tomorrow.
///
/// Students confirm which meals they will attend the next day by 23:59.
/// The cafeteria uses this aggregated data to prepare the correct number of
/// meals.  Confirmation is only valid for a single date (tomorrow).
class MealConfirmation {
  final String studentId;

  /// The date this confirmation applies to (tomorrow).
  final DateTime date;

  final bool breakfast;
  final bool lunch;
  final bool dinner;

  const MealConfirmation({
    required this.studentId,
    required this.date,
    this.breakfast = true,
    this.lunch = true,
    this.dinner = true,
  });

  MealConfirmation copyWith({
    String? studentId,
    DateTime? date,
    bool? breakfast,
    bool? lunch,
    bool? dinner,
  }) {
    return MealConfirmation(
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'date': date.toIso8601String(),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }

  factory MealConfirmation.fromJson(Map<String, dynamic> json) {
    return MealConfirmation(
      studentId: json['studentId'] as String,
      date: DateTime.parse(json['date'] as String),
      breakfast: json['breakfast'] as bool? ?? true,
      lunch: json['lunch'] as bool? ?? true,
      dinner: json['dinner'] as bool? ?? true,
    );
  }
}
