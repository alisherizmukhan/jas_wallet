import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/app_update_decision.dart';
import '../../domain/services/app_store_launcher.dart';

/// Fullscreen, non-dismissible gate shown when [AppUpdateDecision.status] is
/// `requiredUpdate`. No app bar, no back button, no swipe-to-dismiss — the
/// only action available is "Update", which opens the store listing.
///
/// This widget never pops itself: the app only stops showing it on the
/// *next* cold start, once Remote Config confirms the installed version
/// satisfies `minimum_version` again.
class RequiredUpdatePage extends ConsumerStatefulWidget {
  const RequiredUpdatePage({super.key, required this.decision});

  final AppUpdateDecision decision;

  @override
  ConsumerState<RequiredUpdatePage> createState() => _RequiredUpdatePageState();
}

class _RequiredUpdatePageState extends ConsumerState<RequiredUpdatePage> {
  bool _isOpeningStore = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackForceUpdateShown(
      currentVersion: widget.decision.currentVersion.toString(),
      minimumVersion: widget.decision.config.minimumVersion,
    );
  }

  Future<void> _onUpdatePressed() async {
    if (_isOpeningStore) return;
    setState(() => _isOpeningStore = true);
    AnalyticsService.instance.trackUpdateClicked(isForced: true);
    await AppStoreLauncher.open(ref);
    if (mounted) setState(() => _isOpeningStore = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final config = widget.decision.config;

    final title = config.updateTitle.isNotEmpty ? config.updateTitle : l10n.appUpdate_requiredTitle;
    final message = config.updateMessage.isNotEmpty
        ? config.updateMessage
        : l10n.appUpdate_requiredMessage;
    final updateButton =
        config.updateButton.isNotEmpty ? config.updateButton : l10n.appUpdate_updateButton;

    // PopScope absorbs any pop attempt from within this route's own
    // Navigator context — belt-and-suspenders alongside there being no
    // back button, no Dismissible, and no other exit affordance rendered.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: AppIcon(AppIcons.appUpdate, color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isLight ? AppColors.textColor : AppColors.textColorDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    text: updateButton,
                    isLoading: _isOpeningStore,
                    onPressed: _onUpdatePressed,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
