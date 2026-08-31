/// User-visible failure when loading or saving education (academy) entries.
class AcademyApiException implements Exception {
  AcademyApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
