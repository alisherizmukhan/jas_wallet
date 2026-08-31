/// Daily-completion streak. A day counts once every required challenge for
/// that day is completed before it rolls over; missing a day resets
/// [current] to 0 (but never [longest]).
class Streak {
  const Streak({required this.current, required this.longest});

  static const zero = Streak(current: 0, longest: 0);

  final int current;
  final int longest;
}
