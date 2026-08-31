import 'package:app_ui/app_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/app_update_decision.dart';
import '../../domain/services/app_store_launcher.dart';

/// Premium, dismissible "a new version is available" prompt.
///
/// Built on [AppPremiumDialog] — the app's existing Apple Wallet-style
/// bottom sheet (rounded top corners, drag handle, editorial typography,
/// animated presentation via the platform's modal-bottom-sheet transition)
/// — so this stays visually identical to every other confirmation sheet in
/// the app rather than introducing a second bottom-sheet design.
///
/// Remote Config values ([decision.config]) override the localized
/// defaults below whenever Remote Config supplied a non-empty string.
Future<void> showOptionalUpdateSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppUpdateDecision decision,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final config = decision.config;

  final title = config.updateTitle.isNotEmpty ? config.updateTitle : l10n.appUpdate_title;
  final message = config.updateMessage.isNotEmpty
      ? config.updateMessage
      : l10n.appUpdate_optionalMessage;
  final updateButton =
      config.updateButton.isNotEmpty ? config.updateButton : l10n.appUpdate_updateButton;
  final laterButton =
      config.laterButton.isNotEmpty ? config.laterButton : l10n.appUpdate_laterButton;

  AnalyticsService.instance.trackUpdatePromptShown(
    currentVersion: decision.currentVersion.toString(),
    latestVersion: config.latestVersion,
  );

  final confirmed = await AppPremiumDialog.show(
    context: context,
    icon: AppIcons.appUpdate,
    iconColor: AppColors.primary,
    title: title,
    description: message,
    confirmText: updateButton,
    cancelText: laterButton,
  );

  if (confirmed) {
    AnalyticsService.instance.trackUpdateClicked(isForced: false);
    await AppStoreLauncher.open(ref);
  } else {
    AnalyticsService.instance.trackUpdateDismissed();
  }
}
