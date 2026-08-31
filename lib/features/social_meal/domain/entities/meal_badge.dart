import 'package:flutter/material.dart';

/// A meal attendance achievement badge.
///
/// Badges are awarded when [requiredStreak] consecutive meal-streak days
/// are reached. They are purely cosmetic / motivational — no gameplay effect.
@immutable
class MealBadge {
  const MealBadge({
    required this.id,
    required this.emoji,
    required this.nameEn,
    required this.nameRu,
    required this.nameKk,
    required this.requiredStreak,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String emoji;
  final String nameEn;
  final String nameRu;
  final String nameKk;

  /// Streak days needed to unlock.
  final int requiredStreak;

  final bool isUnlocked;
  final DateTime? unlockedAt;

  String nameFor(String? languageCode) => switch (languageCode) {
        'ru' => nameRu,
        'kk' => nameKk,
        _ => nameEn,
      };

  MealBadge copyWith({bool? isUnlocked, DateTime? unlockedAt}) => MealBadge(
        id: id,
        emoji: emoji,
        nameEn: nameEn,
        nameRu: nameRu,
        nameKk: nameKk,
        requiredStreak: requiredStreak,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  // ─── Catalogue ───────────────────────────────────────────────────────────────

  static const List<MealBadge> catalogue = [
    MealBadge(
      id: 'consistent',
      emoji: '🔥',
      nameEn: 'Consistent Student',
      nameRu: 'Стабильный студент',
      nameKk: 'Тұрақты студент',
      requiredStreak: 3,
    ),
    MealBadge(
      id: 'week_streak',
      emoji: '⚡',
      nameEn: '7-Day Meal Streak',
      nameRu: '7-дневная серия',
      nameKk: '7 күндік серия',
      requiredStreak: 7,
    ),
    MealBadge(
      id: 'discipline',
      emoji: '🏅',
      nameEn: '14-Day Discipline',
      nameRu: '14-дневная дисциплина',
      nameKk: '14 күндік тәртіп',
      requiredStreak: 14,
    ),
    MealBadge(
      id: 'legendary',
      emoji: '👑',
      nameEn: 'Legendary Attendance',
      nameRu: 'Легендарная посещаемость',
      nameKk: 'Аңыздық қатысу',
      requiredStreak: 30,
    ),
  ];

  /// Returns [catalogue] with [isUnlocked] set based on [currentStreak].
  static List<MealBadge> evaluateAll(int currentStreak) => catalogue
      .map((b) => b.copyWith(isUnlocked: currentStreak >= b.requiredStreak))
      .toList();

  /// The highest unlocked badge for [currentStreak], or null.
  static MealBadge? highestUnlocked(int currentStreak) {
    final unlocked = catalogue
        .where((b) => currentStreak >= b.requiredStreak)
        .toList();
    return unlocked.isEmpty ? null : unlocked.last;
  }
}
