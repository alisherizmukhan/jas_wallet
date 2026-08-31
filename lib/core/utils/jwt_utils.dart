import 'dart:convert';

/// Decode JWT payload without verification (for reading subject only).
/// Do not use for security validation.
String? decodeJwtSubject(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return json['sub'] as String?;
  } catch (_) {
    return null;
  }
}
