import 'package:app_ui/app_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../features/social_meal/providers/svc_meal_provider.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';


// ── Page ──────────────────────────────────────────────────────────────────────

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final settings = ref.watch(notificationSettingsProvider);
    final svcState = ref.watch(svcMealProvider);
    final isSvcMember = svcState.isMember;
    final isMuteMode = !settings.pushEnabled && isSvcMember;

    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF171717),
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.notifications_settings,
        backgroundColor:
            isLight ? const Color(0xFFF2F2F7) : const Color(0xFF1F1F1F),
        showDivider: false,
      ),
      body: settings.isLoaded
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // ── Master push toggle ──────────────────────────────────────
                _MasterPushCard(
                  isLight: isLight,
                  enabled: settings.pushEnabled,
                  isMuteMode: isMuteMode,
                  l10n: l10n,
                  onChanged: (v) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setPushEnabled(v),
                ),

                const SizedBox(height: 28),

                // ── SVC category — only shown to SVC members ───────────────
                if (isSvcMember) ...[
                  _GroupSection(
                    title: l10n.notifications_sectionMeals,
                    category: NotificationCategory.svc,
                    displayName: l10n.svc_title,
                    subtitle: l10n.notifications_svcSubtitle,
                    settings: settings,
                    isLight: isLight,
                    onToggle: (cat, val) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setCategoryEnabled(cat, val),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Events category — reminders for followed NU events ───
                _GroupSection(
                  title: l10n.notifications_sectionEvents,
                  category: NotificationCategory.events,
                  displayName: l10n.events_nuTitle,
                  subtitle: l10n.notifications_eventsSubtitle,
                  settings: settings,
                  isLight: isLight,
                  onToggle: (cat, val) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setCategoryEnabled(cat, val),
                ),
                const SizedBox(height: 8),

                // ── Footnote ────────────────────────────────────────────────
                _FootnoteText(l10n: l10n, isLight: isLight),
                const SizedBox(height: 16),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

// ── Master push card ──────────────────────────────────────────────────────────

class _MasterPushCard extends StatelessWidget {
  const _MasterPushCard({
    required this.isLight,
    required this.enabled,
    required this.isMuteMode,
    required this.l10n,
    required this.onChanged,
  });

  final bool isLight;
  final bool enabled;
  final bool isMuteMode;
  final AppLocalizations l10n;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.25)
              : (isLight ? const Color(0xFFE5E5EA) : const Color(0xFF38383A)),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(
              enabled
                  ? AppIcons.notification
                  : AppIcons.notification,
              color: enabled ? AppColors.primary : AppColors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notifications_push,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isMuteMode
                      ? l10n.notifications_silentModeDesc
                      : enabled
                          ? l10n.notifications_enablePush
                          : l10n.notifications_pushPaused,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Single category group section ─────────────────────────────────────────────

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.title,
    required this.category,
    required this.settings,
    required this.isLight,
    required this.onToggle,
    this.displayName,
    this.subtitle,
  });

  final String title;
  final NotificationCategory category;
  final NotificationSettingsState settings;
  final bool isLight;
  final void Function(NotificationCategory, bool) onToggle;
  final String? displayName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = settings.categoryToggles[category] ?? true;
    final masterEnabled = settings.pushEnabled;
    final effectiveEnabled = enabled && masterEnabled;
    final iconColor = effectiveEnabled ? category.color : AppColors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
        ),
        // Grouped card
        Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF242424),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE5E5EA)
                  : const Color(0xFF38383A),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 14),
                // Icon
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIcon(category.icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 12),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName ?? category.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: masterEnabled
                              ? theme.textTheme.bodyMedium?.color
                              : AppColors.grey,
                        ),
                      ),
                      Text(
                        subtitle ?? category.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: enabled,
                  onChanged: masterEnabled ? (val) => onToggle(category, val) : null,
                  activeTrackColor: AppColors.primary,
                  thumbColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.white,
                    context,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footnote ──────────────────────────────────────────────────────────────────

class _FootnoteText extends StatelessWidget {
  const _FootnoteText({required this.l10n, required this.isLight});

  final AppLocalizations l10n;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        l10n.notifications_settingsFootnote,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey.withValues(alpha: 0.85),
          height: 1.4,
        ),
      ),
    );
  }
}
