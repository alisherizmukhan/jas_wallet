import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../../core/analytics/analytics_service.dart';
import '../../../../../core/localization/city_provider.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/services/fcm_token_sync_service.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../auth/biometric/biometric_providers.dart';
import '../../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../../user/domain/entities/user_entity.dart';
import '../../../../user/presentation/providers/user_provider.dart';
import '../city_selection_dialog.dart';
import '../language_selection_bottom_sheet.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/section_highlight_provider.dart';
import 'profile_header_new.dart';
import '../../../../../features/rate_app/presentation/providers/rate_app_provider.dart';

/// Unified Profile Dashboard — profile sections + settings list.
///
/// Sections (top → bottom):
///   1. ProfileHeaderNew        — avatar + name + username + level + edit
///   2. ProfileCompletionBanner — dismissible profile fill prompt (if needed)
///   3. _ProfileSettingsSection — full settings list (merged from SettingsPage)
class ProfileDashboardView extends ConsumerWidget {
  const ProfileDashboardView({
    super.key,
    required this.user,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onRatingTap,
  });

  final UserEntity user;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onRatingTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          ProfileHeaderNew(user: user),

          const SizedBox(height: 16),

          // 2. Profile completion banner (dismissible, hidden when 100%)
          _ProfileCompletionBanner(),

          const SizedBox(height: 12),

          // 3. Settings section
          const _ProfileSettingsSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Profile completion banner ─────────────────────────────────────────────────

class _ProfileCompletionBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final completion = ref.watch(
      profileCompletionProvider.select(
        (state) => _CompletionSnapshot(
          shouldShow: state.shouldShowCard,
          percentage: state.percentage,
          completedCount: state.completedCount,
          totalCount: state.totalCount,
        ),
      ),
    );

    if (!completion.shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              final notifier = ref.read(profileCompletionActionsProvider.notifier);
              final section = notifier.getFirstIncompleteSection();
              if (section == null) return;
              ref.read(sectionHighlightProvider.notifier).trigger({section});
              final route = notifier.getRouteForSection(section);
              context.push(route);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.white : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: HomeShadows.card,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: completion.percentage / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: v,
                            strokeWidth: 3.5,
                            backgroundColor: AppColors.primaryLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                          Text(
                            '${(v * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profile_fillProfile,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.profile_completedSteps(
                            completion.completedCount,
                            completion.totalCount,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(AppIcons.chevronRight, size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                ref.read(profileCompletionActionsProvider.notifier).dismiss();
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(AppIcons.close, size: 14, color: AppColors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionSnapshot {
  const _CompletionSnapshot({
    required this.shouldShow,
    required this.percentage,
    required this.completedCount,
    required this.totalCount,
  });
  final bool shouldShow;
  final int percentage;
  final int completedCount;
  final int totalCount;

  @override
  bool operator ==(Object other) =>
      other is _CompletionSnapshot &&
      other.shouldShow == shouldShow &&
      other.percentage == percentage &&
      other.completedCount == completedCount &&
      other.totalCount == totalCount;

  @override
  int get hashCode => Object.hash(shouldShow, percentage, completedCount, totalCount);
}

// ── Settings section ──────────────────────────────────────────────────────────

class _ProfileSettingsSection extends ConsumerWidget {
  const _ProfileSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final city = ref.watch(cityProvider);
    final displayedCity = _resolveCity(city, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Account section ────────────────────────────────────────────────
        _SectionLabel(l10n.settings_basic),

        _SettingsCard(
          isLight: isLight,
          children: [
            AppListTile(
              title: l10n.settings_myProfile,
              leading: AppIcon(AppIcons.editProfile, size: 22, color: AppColors.grey),
              showDivider: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'my_profile');
                context.push(AppRoutes.myProfile);
              },
            ),
            AppListTile(
              title: l10n.settings_notifications,
              leading: AppIcon(AppIcons.notification, size: 22, color: AppColors.grey),
              showDivider: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'notification_settings');
                context.push(AppRoutes.notificationsSettings);
              },
            ),
            AppListTile(
              title: l10n.settings_security,
              leading: AppIcon(AppIcons.security, size: 22, color: AppColors.grey),
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'security');
                context.push(AppRoutes.security);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Preferences section ─────────────────────────────────────────────
        _SectionLabel(l10n.settings_info),

        _SettingsCard(
          isLight: isLight,
          children: [
            AppListTile(
              title: l10n.settings_city,
              leading: AppIcon(AppIcons.location, size: 22, color: AppColors.grey),
              trailing: Text(
                displayedCity,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              showDivider: true,
              onTap: () => _showCityDialog(context, ref, displayedCity),
            ),
            AppListTile(
              title: l10n.settings_appLanguage,
              leading: AppIcon(AppIcons.language, size: 22, color: AppColors.grey),
              trailing: Text(
                _getLanguageName(context, locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              showDivider: true,
              onTap: () => _showLanguageSheet(context, ref),
            ),
            _ThemeToggleRow(
              label: l10n.settings_interfaceMode,
              isDark: themeMode == ThemeMode.dark,
              isLight: isLight,
              onChanged: (isDark) {
                if (isDark) {
                  ref.read(themeProvider.notifier).setDarkMode();
                  AnalyticsService.instance.trackThemeChanged(themeName: 'dark');
                } else {
                  ref.read(themeProvider.notifier).setLightMode();
                  AnalyticsService.instance.trackThemeChanged(themeName: 'light');
                }
              },
            ),
            Divider(
              height: 1,
              color: isLight ? AppColors.borderGrey : AppColors.borderDark,
              indent: 56,
              endIndent: 0,
            ),
            AppListTile(
              title: l10n.settings_aboutApp,
              leading: AppIcon(AppIcons.info, size: 22, color: AppColors.grey),
              showDivider: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'about_app');
                context.push(AppRoutes.aboutApp);
              },
            ),
            AppListTile(
              title: l10n.settings_help,
              leading: AppIcon(AppIcons.chat, size: 22, color: AppColors.grey),
              showDivider: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'help');
                context.push(AppRoutes.help);
              },
            ),
            AppListTile(
              title: l10n.settings_privacyPolicy,
              leading: AppIcon(AppIcons.document, size: 22, color: AppColors.grey),
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'privacy_policy');
                context.push(AppRoutes.privacyPolicy);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Community section ───────────────────────────────────────────────
        _SectionLabel(l10n.settings_community),

        _SettingsCard(
          isLight: isLight,
          children: [
            AppListTile(
              title: l10n.settings_shareJasWallet,
              leading: AppIcon(AppIcons.share, size: 22, color: AppColors.grey),
              showDivider: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'share_jaswallet');
                context.push(AppRoutes.shareApp);
              },
            ),
            AppListTile(
              title: l10n.settings_rateJasWallet,
              leading: AppIcon(AppIcons.star, size: 22, color: AppColors.grey),
              showChevron: false,
              onTap: () => _requestReview(context, ref, l10n),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _GlowingReferralCard(
          isLight: isLight,
          title: l10n.settings_inviteEarn,
          onTap: () {
            AnalyticsService.instance.trackSettingsItemNavigated(destination: 'invite_earn');
            context.push(AppRoutes.referral);
          },
        ),

        const SizedBox(height: 10),

        _SettingsCard(
          isLight: isLight,
          children: [
            AppListTile(
              title: l10n.contest_title,
              leading: AppIcon(AppIcons.trophy, size: 22, color: AppColors.grey),
              showChevron: true,
              onTap: () {
                AnalyticsService.instance.trackSettingsItemNavigated(destination: 'contest');
                context.push(AppRoutes.contest);
              },
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Logout ─────────────────────────────────────────────────────────
        _SettingsCard(
          isLight: isLight,
          children: [
            AppListTile(
              title: l10n.settings_logout,
              leading: AppIcon(AppIcons.logout, size: 22, color: AppColors.error),
              showChevron: false,
              onTap: () => _showLogoutDialog(context, ref, l10n),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _resolveCity(String city, Locale locale) {
    if (city == 'Astana' || city == 'Астана') {
      return locale.languageCode == 'en' ? 'Astana' : 'Астана';
    }
    return locale.languageCode == 'en' ? 'Astana' : 'Астана';
  }

  String _getLanguageName(BuildContext context, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    switch (locale.languageCode) {
      case 'ru':
        return l10n.language_nameRussian;
      case 'en':
        return l10n.language_nameEnglish;
      case 'kk':
        return l10n.language_nameKazakh;
      default:
        return l10n.language_nameRussian;
    }
  }

  void _showCityDialog(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CitySelectionDialog(
        selectedCity: current,
        onCitySelected: (city) {
        ref.read(cityProvider.notifier).setCity(city);
        AnalyticsService.instance.trackSettingsCityChanged(city: city);
      },
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider).languageCode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageSelectionBottomSheet(
        currentLocale: current,
        onLanguageSelected: (code) {
          ref.read(localeProvider.notifier).setLocale(Locale(code));
          AnalyticsService.instance.trackLanguageChanged(languageCode: code);
        },
      ),
    );
  }

  Future<void> _requestReview(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    AnalyticsService.instance.trackRateAppClicked();
    final notifier = ref.read(rateAppProvider.notifier);
    final shown = await notifier.requestReview();
    if (shown) {
      AnalyticsService.instance.trackRateAppCompleted();
      return;
    }
    // In-app review was suppressed/unavailable — open the store listing instead
    // of showing a misleading "thank you" message.
    final opened = await notifier.openStoreListing();
    if (!opened && context.mounted) {
      AppToast.showError(context, l10n.profile_errorGeneric);
    }
  }


  Future<void> _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await AppPremiumDialog.show(
      context: context,
      icon: AppIcons.logout,
      iconColor: const Color(0xFFFF3B30),
      title: l10n.settings_logout,
      description: l10n.settings_logoutConfirm,
      confirmText: l10n.settings_logout,
      cancelText: l10n.common_cancel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    AnalyticsService.instance.trackLogout();

    // Capture providers before any await — ref can go stale once the router
    // navigates away and the widget element is removed from the tree.
    final fcmSync = ref.read(fcmTokenSyncServiceProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final biometricService = ref.read(biometricAuthServiceProvider);

    // Clear in-memory user data.
    ref.read(userProvider.notifier).clearUser();

    // logout() sets state → unauthenticated immediately and fires storage
    // cleanup in the background. The GoRouter redirect fires on the next frame
    // and navigates to welcome — no explicit router.go() needed here.
    await authNotifier.logout(biometricService: biometricService);

    // Fire API cleanup in the background; navigation must not wait on network.
    unawaited(fcmSync.unregisterCurrentToken().catchError((_) {}));
    unawaited(authRepo.logout().catchError((_) {}));
  }
}

// ── Private layout helpers ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.grey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GlowingReferralCard extends StatefulWidget {
  const _GlowingReferralCard({
    required this.isLight,
    required this.title,
    required this.onTap,
  });

  final bool isLight;
  final String title;
  final VoidCallback onTap;

  @override
  State<_GlowingReferralCard> createState() => _GlowingReferralCardState();
}

class _GlowingReferralCardState extends State<_GlowingReferralCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            color: widget.isLight ? AppColors.white : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35 + 0.55 * _anim.value),
              width: 1.5,
            ),
            boxShadow: [
              ...HomeShadows.card,
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08 + 0.18 * _anim.value),
                blurRadius: 10 + 14 * _anim.value,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
        child: AppListTile(
          title: widget.title,
          leading: AppIcon(AppIcons.token, size: 22),
          showChevron: true,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.isLight});

  final List<Widget> children;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: HomeShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow({
    required this.label,
    required this.isDark,
    required this.isLight,
    required this.onChanged,
  });

  final String label;
  final bool isDark;
  final bool isLight;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppIcon(AppIcons.theme, size: 22, color: AppColors.grey),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          _ThemeSegmentedToggle(isDark: isDark, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ThemeSegmentedToggle extends StatelessWidget {
  const _ThemeSegmentedToggle({required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFEEEEF0) : const Color(0xFF2C2C2E);
    final pill = isLight ? Colors.white : const Color(0xFF48484A);
    final activeIcon = isLight ? const Color(0xFF242424) : Colors.white;
    const inactiveIcon = Color(0xFF8E8EA3);

    return Container(
      width: 72,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                color: pill,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isLight
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 4, offset: const Offset(0, 1))]
                    : null,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(child: AppIcon(AppIcons.sun, size: 15, color: !isDark ? activeIcon : inactiveIcon)),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(child: AppIcon(AppIcons.moon, size: 15, color: isDark ? activeIcon : inactiveIcon)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
