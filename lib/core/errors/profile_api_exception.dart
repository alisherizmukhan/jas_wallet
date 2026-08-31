/// Backend / network failures for profile resume APIs (skills, experience, etc.).
class ProfileApiException implements Exception {
  ProfileApiException(this.message, {required this.category});

  final String message;
  final ProfileApiErrorCategory category;

  @override
  String toString() => message;
}

enum ProfileApiErrorCategory {
  network,
  session,
  /// Use [message] when possible (e.g. validation text from API).
  serverDetail,
  unknown,
}
