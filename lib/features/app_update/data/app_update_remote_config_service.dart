import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/app_update_remote_config.dart';

/// Thin, defensive wrapper around [FirebaseRemoteConfig].
///
/// Every public method swallows its own errors and falls back to a safe,
/// no-op value — Remote Config being unreachable (offline first launch,
/// Firebase outage, throttled fetch) must never crash the app or block
/// startup. Callers only ever see [AppUpdateRemoteConfig.empty] in the
/// worst case, which [AppUpdateService] already treats as "no update
/// pressure".
class AppUpdateRemoteConfigService {
  static const _keyLatestVersion = 'latest_version';
  static const _keyMinimumVersion = 'minimum_version';
  static const _keyForceUpdate = 'force_update';
  static const _keyUpdateTitle = 'update_title';
  static const _keyUpdateMessage = 'update_message';
  static const _keyUpdateButton = 'update_button';
  static const _keyLaterButton = 'later_button';

  static const _defaults = <String, Object>{
    _keyLatestVersion: '',
    _keyMinimumVersion: '',
    _keyForceUpdate: false,
    _keyUpdateTitle: '',
    _keyUpdateMessage: '',
    _keyUpdateButton: '',
    _keyLaterButton: '',
  };

  bool _initialized = false;

  /// Configures fetch cadence and registers the safe defaults above.
  ///
  /// `minimumFetchInterval` is production Remote Config caching: real
  /// devices will not re-fetch more often than this, regardless of how many
  /// times [fetchAndActivate] is called — Firebase enforces it
  /// server-side too, so this only avoids pointless local calls. Short in
  /// debug builds so development iteration isn't throttled.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 6),
        ),
      );
      await remoteConfig.setDefaults(_defaults);
      _initialized = true;
    } catch (_) {
      // Firebase not reachable / not initialized yet — getConfig() below
      // still returns a safe empty snapshot via its own try/catch.
    }
  }

  /// Fetches new values (subject to [minimumFetchInterval] caching above)
  /// and activates them. Returns true only if new values were actually
  /// activated; false on any failure or when the cached config is still
  /// fresh enough that Firebase skipped the network call.
  Future<bool> fetchAndActivate() async {
    try {
      return await FirebaseRemoteConfig.instance.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  /// Current values — either freshly activated ones or the last-cached
  /// activation from a previous app run (Remote Config persists activated
  /// values on-device). Never throws.
  AppUpdateRemoteConfig getConfig() {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      return AppUpdateRemoteConfig(
        latestVersion: remoteConfig.getString(_keyLatestVersion),
        minimumVersion: remoteConfig.getString(_keyMinimumVersion),
        forceUpdate: remoteConfig.getBool(_keyForceUpdate),
        updateTitle: remoteConfig.getString(_keyUpdateTitle),
        updateMessage: remoteConfig.getString(_keyUpdateMessage),
        updateButton: remoteConfig.getString(_keyUpdateButton),
        laterButton: remoteConfig.getString(_keyLaterButton),
      );
    } catch (_) {
      return AppUpdateRemoteConfig.empty;
    }
  }
}
