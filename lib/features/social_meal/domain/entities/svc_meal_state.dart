class SVCMealState {
  const SVCMealState({
    this.isMember = false,
    this.isLoaded = false,
    this.isProcessing = false,
    this.lastScanTime,
    this.todayMealsUsedCount = 0,
    this.todayRemainingMealsCount = maxMealsPerDay,
  });

  final bool isMember;
  final bool isLoaded;
  final bool isProcessing;
  final DateTime? lastScanTime;
  final int todayMealsUsedCount;
  final int todayRemainingMealsCount;

  static const int maxMealsPerDay = 3;
  static const int maxMealsPerWeek = 15;
  static const int maxMealsPerMonth = 90;
  static const double dailyCheckPrice = 8990;

  int get todayMealsUsed => todayMealsUsedCount;
  int get todayRemainingMeals => todayRemainingMealsCount;
  int get totalMealsUsed => todayMealsUsedCount;
  int get monthlyMealsUsed => todayMealsUsedCount;
  int get remainingMonthlyMeals =>
      (maxMealsPerMonth - monthlyMealsUsed).clamp(0, maxMealsPerMonth);
  int get remainingMeals =>
      (maxMealsPerWeek - totalMealsUsed).clamp(0, maxMealsPerWeek);
  double get totalWeeklySpent => 0;
  bool get isDailyLimitReached => todayMealsUsedCount >= maxMealsPerDay;
  bool get isWeeklyLimitReached => false;
  bool get isMonthlyLimitReached => monthlyMealsUsed >= maxMealsPerMonth;
  bool get isLimitReached => isDailyLimitReached;
  bool get isCurrentSlotRedeemed => false;
  List<dynamic> get todayRedeemedSlots => const [];

  bool get canScan {
    if (!isMember || isProcessing || isDailyLimitReached) {
      return false;
    }
    if (lastScanTime != null) {
      final elapsed = DateTime.now().difference(lastScanTime!);
      if (elapsed.inSeconds < 5) {
        return false;
      }
    }
    return true;
  }

  SVCMealState copyWith({
    bool? isMember,
    bool? isLoaded,
    bool? isProcessing,
    DateTime? lastScanTime,
    int? todayMealsUsedCount,
    int? todayRemainingMealsCount,
  }) {
    return SVCMealState(
      isMember: isMember ?? this.isMember,
      isLoaded: isLoaded ?? this.isLoaded,
      isProcessing: isProcessing ?? this.isProcessing,
      lastScanTime: lastScanTime ?? this.lastScanTime,
      todayMealsUsedCount: todayMealsUsedCount ?? this.todayMealsUsedCount,
      todayRemainingMealsCount:
          todayRemainingMealsCount ?? this.todayRemainingMealsCount,
    );
  }

  factory SVCMealState.initial() => const SVCMealState();
}
