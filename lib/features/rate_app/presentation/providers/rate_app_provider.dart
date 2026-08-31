import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config/domain/models/app_config_model.dart';
import '../../../app_config/presentation/providers/app_config_provider.dart';

final rateAppProvider =
    StateNotifierProvider<RateAppNotifier, void>((ref) {
  final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfigModel.fallback;
  return RateAppNotifier(config: config);
});

class RateAppNotifier extends StateNotifier<void> {
  RateAppNotifier({required this.config}) : super(null);

  final AppConfigModel config;

  Future<bool> requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> openStoreListing() async {
    try {
      final url = Platform.isIOS ? config.appStoreUrl : config.playStoreUrl;
      if (url.isEmpty) return false;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
