/// Achievement entity for user achievements.
class AchievementEntity {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int level;
  final int currentProgress;
  final int targetProgress;

  const AchievementEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    this.level = 0,
    this.currentProgress = 0,
    this.targetProgress = 0,
  });

  double get progressPercent => 
      targetProgress > 0 ? currentProgress / targetProgress : 0.0;

  String get progressText => '$currentProgress/$targetProgress';

}
