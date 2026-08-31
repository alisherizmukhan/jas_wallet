import 'dart:convert';

/// A single turnstile access attempt with all log messages captured during the flow.
class AccessAttemptLog {
  const AccessAttemptLog({
    required this.timestamp,
    required this.result,
    required this.logs,
  });

  final DateTime timestamp;

  /// One of: granted, rejected, timeout, noKey, failure, permissionDenied
  final String result;

  /// All debug log messages captured during this unlock attempt.
  final List<String> logs;

  bool get isSuccess => result == 'granted';

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'r': result,
        'l': logs,
      };

  factory AccessAttemptLog.fromJson(Map<String, dynamic> json) {
    return AccessAttemptLog(
      timestamp: DateTime.parse(json['ts'] as String),
      result: json['r'] as String,
      logs: (json['l'] as List<dynamic>).cast<String>(),
    );
  }

  static String encodeList(List<AccessAttemptLog> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<AccessAttemptLog> decodeList(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AccessAttemptLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
