/// Outcome of comparing the installed app version against Remote Config.
enum AppUpdateStatus {
  /// Remote Config has not been evaluated yet (initial state).
  unknown,

  /// Installed version satisfies both `minimum_version` and `latest_version`.
  upToDate,

  /// A newer version exists but the installed version is still >= `minimum_version`
  /// and `force_update` is not set — show a dismissible prompt.
  optionalUpdate,

  /// Installed version is below `minimum_version`, or `force_update` is set
  /// and the installed version is below `latest_version` — block usage.
  requiredUpdate,
}
