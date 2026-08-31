import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config/domain/models/app_config_model.dart';
import '../../../app_config/presentation/providers/app_config_provider.dart';

/// Opens the platform store listing for this app.
///
/// Store URLs come from [appConfigProvider] (backend-driven with
/// [AppConfigModel.fallback] as a safe default) — the same source
/// `features/rate_app` already uses, so package identifiers stay
/// configured in exactly one place.
abstract class AppStoreLauncher {
  /// Returns true if a launch was attempted successfully (does not guarantee
  /// the store app itself opened — only that no error was thrown).
  static Future<bool> open(WidgetRef ref) async {
    try {
      final config = ref.read(appConfigProvider).valueOrNull ?? AppConfigModel.fallback;
      final url = Platform.isIOS ? config.appStoreUrl : config.playStoreUrl;
      if (url.isEmpty) return false;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
