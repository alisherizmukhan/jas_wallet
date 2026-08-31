/// User statistics entity for actions section.
class UserStatsEntity {
  final int bonuses;
  final int tokens;
  final int tasks;
  final int activity;
  final int rewards;
  final double motivation;
  
  // Profile views stats
  final int profileViews;
  final double profileViewsChange;
  final List<int> profileViewsHistory;
  
  // Numbers
  final int watched;
  final int searched;
  final int saved;
  final int subscriptions;
  final int subscribers;
  final int savedItems;

  const UserStatsEntity({
    this.bonuses = 0,
    this.tokens = 0,
    this.tasks = 0,
    this.activity = 0,
    this.rewards = 0,
    this.motivation = 0.0,
    this.profileViews = 0,
    this.profileViewsChange = 0.0,
    this.profileViewsHistory = const [],
    this.watched = 0,
    this.searched = 0,
    this.saved = 0,
    this.subscriptions = 0,
    this.subscribers = 0,
    this.savedItems = 0,
  });

  /// Mock stats for development
  static const UserStatsEntity mock = UserStatsEntity(
    bonuses: 500,
    tokens: 371,
    tasks: 44,
    activity: 7,
    rewards: 29,
    motivation: 63,
    profileViews: 231,
    profileViewsChange: 87,
    profileViewsHistory: [20, 40, 60, 80, 60, 40, 30],
    watched: 25,
    searched: 13,
    saved: 7,
    subscriptions: 25,
    subscribers: 13,
    savedItems: 7,
  );
}
