/// Defines the three daily meal time slots for the Social Meal Program.
///
/// Each slot has a fixed time window. Students can only receive one meal
/// per slot, and once a slot's window has passed, it is considered skipped.
///
/// Official time windows:
/// - **Breakfast**: 08:00 – 12:00
/// - **Lunch**: 12:00 – 17:00
/// - **Dinner**: 17:00 – 00:00 (midnight — see [endDateTime])
enum MealSlot {
  breakfast,
  lunch,
  dinner;

  /// Total number of meal slots per day.
  static const int slotsPerDay = 3;

  /// Official daily cost for the full meal program (₸).
  static const double dailyCheckAmount = 8990;

  /// Returns the start hour and minute of this slot.
  (int hour, int minute) get startTime => switch (this) {
        MealSlot.breakfast => (8, 0),
        MealSlot.lunch => (12, 0),
        MealSlot.dinner => (17, 0),
      };

  /// Returns the end hour and minute of this slot. Dinner's `(0, 0)` means
  /// midnight — always resolve it against a date with [endDateTime], never
  /// by combining these raw hour/minute values with the same calendar day
  /// directly, or "end" lands *before* "start".
  (int hour, int minute) get endTime => switch (this) {
        MealSlot.breakfast => (12, 0),
        MealSlot.lunch => (17, 0),
        MealSlot.dinner => (0, 0),
      };

  /// Absolute start moment of this slot on [date].
  DateTime startDateTime(DateTime date) {
    final (h, m) = startTime;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  /// Absolute end moment of this slot on [date] — rolled into the next
  /// calendar day when [endTime] is midnight (dinner), so it is always
  /// after [startDateTime] rather than 17 hours before it.
  DateTime endDateTime(DateTime date) {
    final (h, m) = endTime;
    final end = DateTime(date.year, date.month, date.day, h, m);
    return (h == 0 && m == 0) ? end.add(const Duration(days: 1)) : end;
  }

  /// [endTime] expressed as minutes-since-midnight *of [date]*, for same-day
  /// minute-of-day comparisons ([currentSlot], [passedSlots]) — midnight
  /// means "end of this day" (1440), not "start of this day" (0).
  int get _endMinutesOfDay {
    final (h, m) = endTime;
    return (h == 0 && m == 0) ? 24 * 60 : h * 60 + m;
  }

  /// Human-readable label for the slot.
  String get label => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
      };

  /// Serialization key.
  String get key => name;

  /// Parse from string key.
  static MealSlot fromKey(String key) =>
      MealSlot.values.firstWhere((s) => s.name == key);

  /// Returns the current active meal slot based on [now], or `null` if
  /// no slot is currently active.
  static MealSlot? currentSlot([DateTime? now]) {
    final time = now ?? DateTime.now();
    final minutes = time.hour * 60 + time.minute;

    for (final slot in MealSlot.values) {
      final (startH, startM) = slot.startTime;
      final start = startH * 60 + startM;
      if (minutes >= start && minutes < slot._endMinutesOfDay) return slot;
    }
    return null;
  }

  /// Returns all slots whose time window has already ended relative to [now].
  static List<MealSlot> passedSlots([DateTime? now]) {
    final time = now ?? DateTime.now();
    final minutes = time.hour * 60 + time.minute;

    return MealSlot.values.where((slot) => minutes >= slot._endMinutesOfDay).toList();
  }

  /// Returns all slots whose time window has not yet started relative to [now].
  static List<MealSlot> upcomingSlots([DateTime? now]) {
    final time = now ?? DateTime.now();
    final minutes = time.hour * 60 + time.minute;

    return MealSlot.values.where((slot) {
      final (startH, startM) = slot.startTime;
      return minutes < startH * 60 + startM;
    }).toList();
  }

  /// Human-readable time range string (e.g. "09:00 – 11:30").
  String get timeRange {
    final (startH, startM) = startTime;
    final (endH, endM) = endTime;
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(startH)}:${pad(startM)} – ${pad(endH)}:${pad(endM)}';
  }
}
