/// A lightweight student identity used across Orientation Week — bingo
/// matches, the friend scanner, and the leaderboard.
///
/// [avatarColorIndex] selects one of `app_ui`'s five `AppColors.avatarN`
/// swatches (0-4) — kept as an index rather than a `Color` so this pure-Dart
/// entity has no Flutter dependency.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.avatarColorIndex,
    required this.faculty,
    required this.isFoundationYear,
    required this.country,
    required this.interests,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String initials;
  final int avatarColorIndex;
  final String faculty;
  final bool isFoundationYear;

  /// A real profile photo, when one is known — the signed-in student's own
  /// (from their JasWallet profile) or another student's (if the backend
  /// ever sends one). Null falls back to the initials-on-colour avatar every
  /// Orientation Week surface already knows how to draw.
  final String? photoUrl;

  /// Shown as a badge chip on the post-scan Friend Profile screen.
  final String country;

  /// Shown as tag chips on the post-scan Friend Profile screen.
  final List<String> interests;

  StudentProfile copyWith({String? fullName, String? initials, String? photoUrl}) {
    return StudentProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      avatarColorIndex: avatarColorIndex,
      faculty: faculty,
      isFoundationYear: isFoundationYear,
      country: country,
      interests: interests,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
