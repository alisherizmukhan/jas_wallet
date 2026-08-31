import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_item.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final isRead = notification.isRead;
    final cat = notification.category;
    final createdAt = notification.createdAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isRead
                  ? (isLight ? AppColors.white : const Color(0xFF1D1D1D))
                  : cat.color.withValues(alpha: isLight ? 0.08 : 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRead
                    ? (isLight ? AppColors.borderGrey : const Color(0xFF2A2A2A))
                    : cat.color.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AppIcon(cat.icon, color: cat.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.displayName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cat.color,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(createdAt, l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isRead
                              ? AppColors.grey
                              : theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0E5BB5),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 13),
                    const SizedBox(height: 8),
                    AppIcon(
                      AppIcons.chevronRight,
                      size: 18,
                      color: AppColors.grey.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.common_now;
    } else if (difference.inMinutes < 60) {
      return l10n.common_minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.common_hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.common_daysAgo(difference.inDays);
    } else {
      return '${dateTime.day}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }
  }
}
