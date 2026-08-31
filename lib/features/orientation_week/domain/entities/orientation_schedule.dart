/// Which programme a student is on.
///
/// The official timetable runs two parallel columns every day with genuinely
/// different sessions, so this is not a display preference — it decides which
/// half of the week a student is actually being told about.
enum StudentTrack { undergraduate, graduate }

extension StudentTrackX on StudentTrack {
  /// The value stored in `schedule.json`.
  String get key => switch (this) {
        StudentTrack.undergraduate => 'ug',
        StudentTrack.graduate => 'gr',
      };

  String get shortLabel => switch (this) {
        StudentTrack.undergraduate => 'UG',
        StudentTrack.graduate => 'Gr',
      };

  String get label => switch (this) {
        StudentTrack.undergraduate => 'Undergraduate',
        StudentTrack.graduate => 'Graduate',
      };

  static StudentTrack? fromKey(String? raw) => switch (raw) {
        'ug' => StudentTrack.undergraduate,
        'gr' => StudentTrack.graduate,
        _ => null,
      };
}

/// How strongly a session is expected of a student, as annotated on the grid.
enum SessionImportance { mandatory, recommended, optional }

extension SessionImportanceX on SessionImportance {
  String get label => switch (this) {
        SessionImportance.mandatory => 'Mandatory',
        SessionImportance.recommended => 'Recommended',
        SessionImportance.optional => 'Optional',
      };

  static SessionImportance fromKey(String? raw) => switch (raw) {
        'mandatory' => SessionImportance.mandatory,
        'recommended' => SessionImportance.recommended,
        _ => SessionImportance.optional,
      };
}

/// One cell of the timetable.
class ScheduleSession {
  const ScheduleSession({
    required this.id,
    required this.date,
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    required this.importance,
    this.track,
    this.place,
    this.note,
    this.link,
    this.linkLabel,
  });

  final String id;

  /// Midnight on the session's day. Times live in [startMinutes].
  final DateTime date;

  final String title;

  /// Minutes since midnight, so ordering and formatting never go through a
  /// `DateTime` that a timezone could shift under us.
  final int startMinutes;
  final int endMinutes;

  final SessionImportance importance;

  /// Null means the session runs for both tracks (lunch, evening activities).
  final StudentTrack? track;

  final String? place;

  /// The small print — attendee counts, meeting IDs, passcodes.
  final String? note;

  final String? link;
  final String? linkLabel;

  bool get isForBothTracks => track == null;

  /// True when this session belongs on [viewer]'s timetable.
  bool visibleTo(StudentTrack viewer) => track == null || track == viewer;

  /// "09:00", 24-hour, zero-padded — the grid's own format.
  String get startLabel => _hhmm(startMinutes);
  String get endLabel => _hhmm(endMinutes);
  String get timeRangeLabel => '$startLabel – $endLabel';

  static String _hhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Parses "09:00" into minutes since midnight. Returns 0 on anything
  /// unparseable rather than throwing — one bad cell must not take the whole
  /// week down.
  static int parseMinutes(String? raw) {
    if (raw == null) return 0;
    final parts = raw.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }
}

/// One day of the week, with its sessions in time order.
class ScheduleDay {
  const ScheduleDay({required this.date, required this.label, required this.sessions});

  final DateTime date;

  /// "Monday" — from the file, so it never disagrees with the printed grid.
  final String label;

  final List<ScheduleSession> sessions;

  /// This day as [viewer] sees it: their own track plus the shared sessions.
  List<ScheduleSession> forTrack(StudentTrack viewer) =>
      sessions.where((s) => s.visibleTo(viewer)).toList();

  int mandatoryCountFor(StudentTrack viewer) => forTrack(viewer)
      .where((s) => s.importance == SessionImportance.mandatory)
      .length;
}

/// The whole week.
class OrientationSchedule {
  const OrientationSchedule({required this.days});

  final List<ScheduleDay> days;

  bool get isEmpty => days.isEmpty;

  DateTime? get firstDay => days.isEmpty ? null : days.first.date;
  DateTime? get lastDay => days.isEmpty ? null : days.last.date;

  /// The day matching [date], or null if the week does not cover it.
  ScheduleDay? dayFor(DateTime date) {
    for (final day in days) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }

  /// What the schedule should open on: today if the week is running, the first
  /// day if it has not started, the last day if it is over.
  ///
  /// Opening a finished week on "today" would show an empty page during the
  /// whole rest of the year, which is when most people will look at it.
  DateTime initialDate(DateTime now) {
    final first = firstDay;
    final last = lastDay;
    if (first == null || last == null) return now;
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(first)) return first;
    if (today.isAfter(last)) return last;
    return today;
  }
}
