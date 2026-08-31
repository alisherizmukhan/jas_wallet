/// Backend-driven application configuration.
///
/// Populated from GET /app/config. While the backend is unavailable,
/// [AppConfigModel.fallback] is used — no UI changes are needed when
/// backend integration is added later.
///
/// BACKEND INTEGRATION (see docs/backend/referral_and_share_backend_requirements.md):
///   Replace [AppConfigRepositoryImpl.getConfig] with an HTTP call.
///   This model and its consumers require no changes.
class AppConfigModel {
  const AppConfigModel({
    required this.appStoreUrl,
    required this.playStoreUrl,
    required this.shareUrl,
    required this.referralEnabled,
    required this.referralMessageTemplate,
  });

  /// iOS App Store URL. Empty string = store page unavailable.
  final String appStoreUrl;

  /// Google Play Store URL. Empty string = store page unavailable.
  final String playStoreUrl;

  /// Universal download/share URL displayed in share sheets and referral messages.
  final String shareUrl;

  /// Feature flag — hide referral UI when false.
  final bool referralEnabled;

  /// Template for the referral share message.
  /// Supported placeholders: {code} → referral code, {url} → shareUrl.
  final String referralMessageTemplate;

  static const AppConfigModel fallback = AppConfigModel(
    appStoreUrl: 'https://apps.apple.com/app/id6784542779',
    playStoreUrl:
        'https://play.google.com/store/apps/details?id=com.jaswallet.app',
    shareUrl: 'https://jasaim.kz/download',
    referralEnabled: true,
    referralMessageTemplate:
        'Join me on Jas Wallet.\n\n'
        'Manage your student life in one place.\n\n'
        'Use my referral code:\n{code}\n\n'
        'Download:\n{url}',
  );

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      appStoreUrl: json['appStoreUrl'] as String? ?? '',
      playStoreUrl: json['playStoreUrl'] as String? ?? '',
      shareUrl: json['shareUrl'] as String? ?? fallback.shareUrl,
      referralEnabled: json['referralEnabled'] as bool? ?? true,
      referralMessageTemplate: json['referralMessageTemplate'] as String? ??
          fallback.referralMessageTemplate,
    );
  }

  Map<String, dynamic> toJson() => {
        'appStoreUrl': appStoreUrl,
        'playStoreUrl': playStoreUrl,
        'shareUrl': shareUrl,
        'referralEnabled': referralEnabled,
        'referralMessageTemplate': referralMessageTemplate,
      };

  AppConfigModel copyWith({
    String? appStoreUrl,
    String? playStoreUrl,
    String? shareUrl,
    bool? referralEnabled,
    String? referralMessageTemplate,
  }) {
    return AppConfigModel(
      appStoreUrl: appStoreUrl ?? this.appStoreUrl,
      playStoreUrl: playStoreUrl ?? this.playStoreUrl,
      shareUrl: shareUrl ?? this.shareUrl,
      referralEnabled: referralEnabled ?? this.referralEnabled,
      referralMessageTemplate:
          referralMessageTemplate ?? this.referralMessageTemplate,
    );
  }

  /// Build the share message string, substituting template placeholders.
  ///
  /// [languageCode] selects the localized landing page (see [localizedUrl]).
  String buildShareMessage({
    required String referralCode,
    String languageCode = 'ru',
  }) {
    return referralMessageTemplate
        .replaceAll('{code}', referralCode)
        .replaceAll('{url}', localizedUrl(shareUrl, languageCode));
  }

  /// Build a plain share message without a referral code.
  String buildAppShareMessage({String languageCode = 'ru'}) {
    return referralMessageTemplate
        .replaceAll('{code}', '')
        .replaceAll('{url}', localizedUrl(shareUrl, languageCode));
  }

  /// Insert a locale segment into a jasaim.kz URL for non-default languages.
  ///
  /// The website serves `ru` at the root and `en`/`kk` under a language prefix:
  ///   `https://jasaim.kz/download`        (ru — canonical)
  ///   `https://jasaim.kz/en/download`     (en)
  ///   `https://jasaim.kz/kk/download`     (kk)
  ///
  /// Unknown/`ru` locales return [url] unchanged. Safe on malformed input.
  static String localizedUrl(String url, String languageCode) {
    if (languageCode != 'en' && languageCode != 'kk') return url;
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return url;
      return uri.replace(path: '/$languageCode${uri.path}').toString();
    } catch (_) {
      return url;
    }
  }
}
