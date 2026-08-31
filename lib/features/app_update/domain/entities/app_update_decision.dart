import 'package:pub_semver/pub_semver.dart';

import 'app_update_remote_config.dart';
import 'app_update_status.dart';

/// Result of [AppUpdateService.evaluate] — everything the UI layer needs to
/// render the right prompt, with nothing left to recompute.
class AppUpdateDecision {
  const AppUpdateDecision({
    required this.status,
    required this.config,
    required this.currentVersion,
  });

  /// Initial state before the first evaluation completes.
  static final unknown = AppUpdateDecision(
    status: AppUpdateStatus.unknown,
    config: AppUpdateRemoteConfig.empty,
    currentVersion: Version.none,
  );

  final AppUpdateStatus status;
  final AppUpdateRemoteConfig config;
  final Version currentVersion;

  @override
  String toString() =>
      'AppUpdateDecision(status: $status, currentVersion: $currentVersion, '
      'latestVersion: ${config.latestVersion}, minimumVersion: ${config.minimumVersion})';
}
