/// Typed snapshot of the 7 Remote Config keys this feature reads.
///
/// String fields are the RAW values from Remote Config — empty string means
/// "not set" (the caller falls back to a localized default; see
/// `presentation/widgets/optional_update_sheet.dart` and
/// `presentation/pages/required_update_page.dart`). This class never
/// throws — construct it from [AppUpdateRemoteConfigService.getConfig],
/// which guarantees safe defaults even if Remote Config itself failed.
class AppUpdateRemoteConfig {
  const AppUpdateRemoteConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateButton,
    required this.laterButton,
  });

  /// All keys empty/false — the safe no-op snapshot used when Remote Config
  /// has never been fetched or fetch/activate failed.
  static const empty = AppUpdateRemoteConfig(
    latestVersion: '',
    minimumVersion: '',
    forceUpdate: false,
    updateTitle: '',
    updateMessage: '',
    updateButton: '',
    laterButton: '',
  );

  /// Remote Config key: `latest_version`.
  final String latestVersion;

  /// Remote Config key: `minimum_version`.
  final String minimumVersion;

  /// Remote Config key: `force_update`.
  final bool forceUpdate;

  /// Remote Config key: `update_title`.
  final String updateTitle;

  /// Remote Config key: `update_message`.
  final String updateMessage;

  /// Remote Config key: `update_button`.
  final String updateButton;

  /// Remote Config key: `later_button`.
  final String laterButton;
}
