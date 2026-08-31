import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../../features/auth/presentation/providers/auth_repository_provider.dart';
import '../providers/auth_provider.dart' show authStorageServiceProvider;
import 'auth_storage_service.dart';
import 'fcm_service.dart';

/// Syncs the local FCM device token with the JasWallet backend.
///
/// Two independent, legitimate triggers call into this service — a real FCM
/// token rotation, and every transition of the user's auth state into
/// `authenticated` (PIN/biometric unlock included, not just fresh login).
/// Both are meaningful conditions to *consider* syncing on, but the token
/// itself is stable for weeks-to-months, so most of those calls would
/// otherwise PUT an unchanged value. [syncToken] is idempotent — it compares
/// against the last value actually confirmed synced and no-ops when nothing
/// changed, rather than the callers needing to coordinate with each other.
class FcmTokenSyncService {
  FcmTokenSyncService(this._apiClient, this._authStorage);

  final ApiClient _apiClient;
  final AuthStorageService _authStorage;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Register the current device token when the user is authenticated.
  Future<void> syncCurrentToken() async {
    final token = await FCMService.getStoredToken();
    if (token == null || token.isEmpty) return;
    await syncToken(token);
  }

  /// Upsert a specific FCM token on the backend.
  ///
  /// No-ops if [token] is identical to the last value this method
  /// successfully synced — the common case for every call site except a
  /// genuine token rotation or first-ever registration.
  Future<void> syncToken(String token) async {
    try {
      final lastSynced = await _authStorage.getLastSyncedFcmToken();
      if (lastSynced == token) return;

      await _apiClient.dio.put(
        '/devices/fcm-token',
        data: {
          'token': token,
          'platform': _platform,
        },
      );
      await _authStorage.markFcmTokenSynced(token);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token sync failed: ${e.response?.statusCode} ${e.message}');
      }
    } catch (_) {
      // Push registration must never break auth or navigation flows.
    }
  }

  /// Deactivate the current device token before logout.
  Future<void> unregisterCurrentToken() async {
    final token = await FCMService.getStoredToken();
    if (token == null || token.isEmpty) return;
    await unregisterToken(token);
  }

  /// Deactivate a specific token on the backend.
  Future<void> unregisterToken(String token) async {
    try {
      await _apiClient.dio.delete(
        '/devices/fcm-token',
        data: {'token': token},
      );
      // A deactivated token is no longer registered backend-side — the next
      // login must be free to re-PUT the same token value if it hasn't
      // rotated, rather than treating it as "already synced" from a session
      // that just unregistered it.
      final lastSynced = await _authStorage.getLastSyncedFcmToken();
      if (lastSynced == token) {
        await _authStorage.clearLastSyncedFcmToken();
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token unregister failed: ${e.response?.statusCode} ${e.message}');
      }
    } catch (_) {}
  }
}

final fcmTokenSyncServiceProvider = Provider<FcmTokenSyncService>((ref) {
  return FcmTokenSyncService(
    ref.watch(apiClientProvider),
    ref.watch(authStorageServiceProvider),
  );
});
