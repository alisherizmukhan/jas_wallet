/// User-visible failure when loading or saving profile activities.
class ActivityApiException implements Exception {
  ActivityApiException(this.message, {this.kind = ActivityErrorKind.serverDetail});

  final String message;
  final ActivityErrorKind kind;

  @override
  String toString() => message;
}

enum ActivityErrorKind {
  network,
  session,
  imageTooLarge,
  imageRead,
  maxPhotos,
  /// Prefer showing [message] (may be English from API).
  serverDetail,
  unknown,
}
