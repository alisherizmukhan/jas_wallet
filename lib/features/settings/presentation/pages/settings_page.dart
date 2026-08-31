import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../tutorial/data/tutorial_service.dart';
import '../../../tutorial/domain/tutorial_content.dart';
import '../../../tutorial/domain/tutorial_ids.dart';
import '../../../tutorial/presentation/pages/tutorial_story_page.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../widgets/profile_dashboard/profile_dashboard_view.dart';

/// Settings page — unified profile dashboard + settings.
///
/// Shows the full profile header, completion card, and all settings
/// sections in a single scrollable view.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Whether the first-launch tutorial overlay is currently shown. Decided
  /// synchronously in initState so it covers the first frame (no flash) while
  /// the page loads behind it.
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _showTutorial = TutorialService.instance.shouldShowSync(TutorialIds.profile);
    if (_showTutorial) {
      TutorialService.instance.markSeenSync(TutorialIds.profile);
    }
  }

  /// Overlays the first-launch tutorial on top of [page] so it appears
  /// instantly on the first frame, while [page] builds/loads behind it.
  Widget _withTutorial(Widget page) {
    if (!_showTutorial) return page;
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _showTutorial = false);
            },
            child: TutorialStoryPage(
              tutorialId: TutorialIds.profile,
              slides: TutorialContent.profile(AppLocalizations.of(context)!),
              onDismiss: () => setState(() => _showTutorial = false),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    final Widget scaffold = Scaffold(
      appBar: AppAppBar(
        title: l10n.settings_title,
        showBackButton: true,
        showDivider: false,
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final user = ref.watch(userProvider).valueOrNull;

          if (user == null) {
            return const _SettingsPagePlaceholder();
          }

          return ProfileDashboardView(
            user: user,
            onFollowersTap: null,
            onFollowingTap: null,
            onRatingTap: null,
          );
        },
      ),
    );
    return _withTutorial(scaffold);
  }
}

class _SettingsPagePlaceholder extends StatelessWidget {
  const _SettingsPagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final surface = isLight ? AppColors.fieldBackground : AppColors.surfaceDark;

    Widget line(double width, {double height = 14}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          ),
          const SizedBox(height: 16),
          line(170, height: 18),
          const SizedBox(height: 8),
          line(110, height: 14),
          const SizedBox(height: 24),
          line(double.infinity, height: 92),
          const SizedBox(height: 20),
          line(120, height: 18),
          const SizedBox(height: 12),
          line(double.infinity, height: 72),
          const SizedBox(height: 12),
          line(double.infinity, height: 72),
          const SizedBox(height: 12),
          line(double.infinity, height: 72),
        ],
      ),
    );
  }
}
