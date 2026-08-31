import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_item.dart';

/// Premium activity-detail bottom sheet — Revolut / Apple Wallet aesthetic.
///
/// Navigation contract:
///   • The sheet pops itself (single pop) before calling [onOpen].
///   • The parent's [onOpen] callback must NOT call Navigator.pop again.
///     It should defer its navigation via addPostFrameCallback so the
///     navigator is not locked during the pop transition.
class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({
    super.key,
    required this.notification,
    this.onOpen,
    this.actionLabel,
    this.actionIcon,
  });

  final NotificationItem notification;

  /// Called after the sheet dismisses itself. The parent uses this to navigate.
  final VoidCallback? onOpen;

  /// Contextual action button label. Falls back to l10n.notifications_openScreen.
  final String? actionLabel;

  /// Contextual action button icon. Falls back to category.actionButtonIcon.
  final AppIconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final cat = notification.category;
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1C1C2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFF3A3A4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Centered icon ────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppIcon(cat.icon, color: cat.color, size: 30),
              ),
              const SizedBox(height: 14),

              // ── Category badge + optional unread dot ─────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnread) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cat.color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ── Timestamp ────────────────────────────────────────────────
              Text(
                _formatFullDate(notification.createdAt, l10n),
                style: TextStyle(
                  fontSize: 12,
                  color: isLight
                      ? AppColors.grey
                      : const Color(0xFF888899),
                ),
              ),
              const SizedBox(height: 20),

              // ── Separator ────────────────────────────────────────────────
              _Divider(isLight: isLight),
              const SizedBox(height: 18),

              // ── Title ────────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Body ─────────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isLight
                        ? const Color(0xFF666677)
                        : const Color(0xFFAAABBB),
                    height: 1.55,
                  ),
                ),
              ),

              // ── Open action ──────────────────────────────────────────────
              if (onOpen != null) ...[
                const SizedBox(height: 24),
                _Divider(isLight: isLight),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _OpenButton(
                    label: actionLabel ?? l10n.notifications_openScreen,
                    icon: actionIcon ?? cat.actionButtonIcon,
                    onTap: () {
                      // Single pop — the parent callback must NOT pop again.
                      Navigator.of(context).pop();
                      onOpen?.call();
                    },
                    isLight: isLight,
                  ),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final todayDate = DateTime(now.year, now.month, now.day);
    final dtDate = DateTime(dt.year, dt.month, dt.day);

    if (dtDate == todayDate) {
      return '${l10n.notifications_today} · $time';
    } else if (dtDate == todayDate.subtract(const Duration(days: 1))) {
      return '${l10n.notifications_yesterday} · $time';
    } else if (diff.inDays < 7) {
      return '${l10n.common_daysAgo(diff.inDays)} · $time';
    } else {
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year} · $time';
    }
  }
}

// ── Compact "Open" action button ──────────────────────────────────────────────

class _OpenButton extends StatelessWidget {
  const _OpenButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLight,
  });

  final String label;
  final AppIconData icon;
  final VoidCallback onTap;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('notif_open_btn'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 15, color: AppColors.primary),
            SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Thin separator ────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.isLight});
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: isLight ? AppColors.borderGrey : const Color(0xFF2A2A3A),
    );
  }
}
