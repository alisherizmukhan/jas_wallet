import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../app_config/domain/models/app_config_model.dart';
import '../../../app_config/presentation/providers/app_config_provider.dart';

class SharePage extends ConsumerStatefulWidget {
  const SharePage({super.key});

  @override
  ConsumerState<SharePage> createState() => _SharePageState();
}

class _SharePageState extends ConsumerState<SharePage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackShareAppOpened();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfigModel.fallback;

    return Scaffold(
      appBar: AppAppBar(
        title: l10n.share_shareApp,
        showBackButton: true,
        showDivider: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isLight ? AppColors.white : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: HomeShadows.card,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isLight
                          ? AppColors.primaryLight
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: AppIcon(AppIcons.share, size: 32, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.share_shareApp,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.share_shareAppSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            AppPrimaryButton(
              text: l10n.share_shareApp,
              onPressed: () => _share(l10n, config),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _share(AppLocalizations l10n, AppConfigModel config) async {
    AnalyticsService.instance.trackShareAppClicked(method: 'share_page');
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
      final shareUrl = AppConfigModel.localizedUrl(
        config.shareUrl,
        Localizations.localeOf(context).languageCode,
      );
      await SharePlus.instance.share(
        ShareParams(
          text: '${l10n.appName}\n\n$shareUrl',
          title: l10n.share_shareApp,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {}
  }
}
