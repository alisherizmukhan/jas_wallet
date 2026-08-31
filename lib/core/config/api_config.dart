/// API configuration for JasWallet backend.
///
/// Base URL for backend API. Override for different environments:
/// - Development (emulator): use 10.0.2.2:8000 for Android, localhost for iOS
/// - Production: set via build config or environment
class ApiConfig {
  ApiConfig._();

  /// Base URL for the JasWallet backend API (without trailing slash).
  /// Default points to the current JasWallet backend server.
  /// Override with `--dart-define=API_BASE_URL=...` when needed.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.jasaim.kz',
  );

  /// API v1 prefix
  static const String apiPrefix = '/api/v1';

  /// Full base URL including API prefix
  static String get apiBaseUrl => '$baseUrl$apiPrefix';
}
