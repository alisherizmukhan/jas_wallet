import 'dart:io';

/// Lightweight connectivity probe — used only for explicit user actions
/// (pull-to-refresh) to decide whether to attempt API calls or surface
/// a "No internet" toast immediately.
///
/// For background auto-refreshes always attempt the call and fail silently;
/// do NOT use this service to gate background operations.
class ConnectivityService {
  ConnectivityService._();

  /// Returns [true] if the device can reach the internet right now.
  ///
  /// DNS lookup typically fails in < 100 ms when offline.
  /// The 3-second timeout is a safety net for captive portals / slow DNS.
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
