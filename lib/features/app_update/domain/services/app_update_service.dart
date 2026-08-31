import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../data/app_update_remote_config_service.dart';
import '../entities/app_update_decision.dart';
import '../entities/app_update_remote_config.dart';
import '../entities/app_update_status.dart';
import 'app_version_comparator.dart';

/// Orchestrates the in-app update check: Remote Config + the installed
/// version + [AppVersionComparator] in, an [AppUpdateDecision] out.
///
/// Deliberately UI-free — no [BuildContext], no navigation, no dialogs.
/// Presentation code (`presentation/providers/app_update_provider.dart`)
/// owns turning a decision into a bottom sheet or a blocking page.
class AppUpdateService {
  AppUpdateService({AppUpdateRemoteConfigService? remoteConfigService})
      : _remoteConfigService = remoteConfigService ?? AppUpdateRemoteConfigService();

  final AppUpdateRemoteConfigService _remoteConfigService;

  static final _fallbackVersion = Version(0, 0, 0);

  /// Debug-only local override so the optional sheet / required page can be
  /// previewed with `flutter run` without touching Firebase Remote Config
  /// at all — see docs/firebase_remote_config_updates.md "Testing locally".
  ///
  ///   flutter run --dart-define=DEBUG_UPDATE_STATE=optional
  ///   flutter run --dart-define=DEBUG_UPDATE_STATE=required
  ///
  /// Gated on [kDebugMode] so it is structurally impossible for this to be
  /// live in a release build, even if a build script accidentally left the
  /// dart-define set.
  static const _debugUpdateState = String.fromEnvironment('DEBUG_UPDATE_STATE');

  /// Runs the full check: initialize Remote Config, fetch & activate
  /// (respecting its cache window), read the config, compare against the
  /// installed version, and return a decision. Never throws — any failure
  /// anywhere in this chain degrades to [AppUpdateStatus.upToDate] so a
  /// Remote Config outage can never block the app.
  Future<AppUpdateDecision> evaluate() async {
    final currentVersion = await _currentVersion();

    if (kDebugMode) {
      final debugStatus = switch (_debugUpdateState) {
        'required' => AppUpdateStatus.requiredUpdate,
        'optional' => AppUpdateStatus.optionalUpdate,
        'upToDate' => AppUpdateStatus.upToDate,
        _ => null,
      };
      if (debugStatus != null) {
        return AppUpdateDecision(
          status: debugStatus,
          config: _debugConfig(debugStatus),
          currentVersion: currentVersion,
        );
      }
    }

    try {
      await _remoteConfigService.initialize();
      await _remoteConfigService.fetchAndActivate();
      final config = _remoteConfigService.getConfig();

      final latest = AppVersionComparator.tryParse(config.latestVersion);
      final minimum = AppVersionComparator.tryParse(config.minimumVersion);

      final belowMinimum = AppVersionComparator.isBelow(currentVersion, minimum);
      final belowLatestAndForced =
          config.forceUpdate && AppVersionComparator.isBelow(currentVersion, latest);

      final AppUpdateStatus status;
      if (belowMinimum || belowLatestAndForced) {
        status = AppUpdateStatus.requiredUpdate;
      } else if (AppVersionComparator.isBelow(currentVersion, latest)) {
        status = AppUpdateStatus.optionalUpdate;
      } else {
        status = AppUpdateStatus.upToDate;
      }

      return AppUpdateDecision(
        status: status,
        config: config,
        currentVersion: currentVersion,
      );
    } catch (_) {
      return AppUpdateDecision(
        status: AppUpdateStatus.upToDate,
        config: AppUpdateRemoteConfig.empty,
        currentVersion: currentVersion,
      );
    }
  }

  /// Synthetic Remote Config snapshot for [_debugUpdateState] — plausible
  /// version strings so the sheet/page renders with realistic-looking
  /// copy ("Update to 99.0.0") without needing real Remote Config values.
  AppUpdateRemoteConfig _debugConfig(AppUpdateStatus status) {
    const debugVersion = '99.0.0';
    return AppUpdateRemoteConfig(
      latestVersion: status == AppUpdateStatus.upToDate ? '' : debugVersion,
      minimumVersion: status == AppUpdateStatus.requiredUpdate ? debugVersion : '',
      forceUpdate: false,
      updateTitle: '',
      updateMessage: '',
      updateButton: '',
      laterButton: '',
    );
  }

  Future<Version> _currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersionComparator.tryParse(info.version) ?? _fallbackVersion;
    } catch (_) {
      return _fallbackVersion;
    }
  }
}
