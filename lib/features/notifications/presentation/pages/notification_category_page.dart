import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';

class NotificationCategoryPage extends ConsumerStatefulWidget {
  const NotificationCategoryPage({
    super.key,
    required this.sectionCategory,
  });

  final NotificationCategory sectionCategory;

  @override
  ConsumerState<NotificationCategoryPage> createState() =>
      _NotificationCategoryPageState();
}

class _NotificationCategoryPageState extends ConsumerState<NotificationCategoryPage> {
  late final ScrollController _scrollController;
  bool _isMarkingSectionRead = false;
  bool _didInitialBottomScroll = false;
  final GlobalKey _bottomAnchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final theme = Theme.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final isEnabled = settings.categoryToggles[widget.sectionCategory] ?? true;

    return Scaffold(
      appBar: AppAppBar(
        showBackButton: true,
        title: widget.sectionCategory.displayName,
      ),
      body: ref.watch(notificationsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.profile_errorGeneric,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (items) {
              if (!isEnabled) {
                return _buildDisabledState(theme, l10n);
              }

              final sectionItems = _itemsForSection(items, widget.sectionCategory)
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

              _markSectionReadIfNeeded(sectionItems);
              _scheduleInitialBottomPosition(sectionItems.isNotEmpty);

              if (sectionItems.isEmpty) {
                return _buildEmptyState(theme, l10n);
              }

              final grouped = _groupByDate(sectionItems, l10n);
              final dateKeys = grouped.keys.toList();

              // Flatten date-group headers + their items into one indexable
              // list so ListView.builder can lazily build rows instead of
              // eagerly constructing the entire (unbounded, account-lifetime)
              // notification history up front.
              final flatRows = <Object>[];
              for (final dayKey in dateKeys) {
                flatRows.add(dayKey);
                flatRows.addAll(grouped[dayKey] ?? const <NotificationItem>[]);
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(notificationsProvider.notifier).load(),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: flatRows.length + 1, // +1 for the bottom anchor
                  itemBuilder: (context, index) {
                    if (index == flatRows.length) {
                      return SizedBox(key: _bottomAnchorKey, height: 1);
                    }

                    final row = flatRows[index];
                    if (row is String) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Text(
                          row.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      );
                    }
                    return _CategoryMessageCard(
                      notification: row as NotificationItem,
                    );
                  },
                ),
              );
            },
          ),
    );
  }

  void _scheduleInitialBottomPosition(bool hasItems) {
    if (!hasItems || _didInitialBottomScroll) {
      return;
    }
    _didInitialBottomScroll = true;
    _jumpToBottomSoon();
  }

  void _jumpToBottomSoon({int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final anchorContext = _bottomAnchorKey.currentContext;
      if (anchorContext != null) {
        Scrollable.ensureVisible(
          anchorContext,
          duration: Duration.zero,
          alignment: 1,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }

      Future<void>.delayed(const Duration(milliseconds: 16), () {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

        if (_bottomAnchorKey.currentContext == null && attempt < 4) {
          _jumpToBottomSoon(attempt: attempt + 1);
        }
      });
    });
  }

  void _markSectionReadIfNeeded(List<NotificationItem> sectionItems) {
    if (_isMarkingSectionRead) {
      return;
    }

    final unreadIds = sectionItems
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList(growable: false);

    if (unreadIds.isEmpty) {
      return;
    }

    _isMarkingSectionRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isMarkingSectionRead = false;
        return;
      }

      ref
          .read(notificationsProvider.notifier)
          .markReadMany(unreadIds)
          .whenComplete(() {
        _isMarkingSectionRead = false;
        _jumpToBottomSoon();
      });
    });
  }

  List<NotificationItem> _itemsForSection(
    List<NotificationItem> items,
    NotificationCategory section,
  ) {
    return items.where((item) {
      if (section == NotificationCategory.svc) {
        return item.category == NotificationCategory.svc;
      }
      return item.category != NotificationCategory.svc;
    }).toList();
  }

  Map<String, List<NotificationItem>> _groupByDate(
    List<NotificationItem> items,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<NotificationItem>>{};

    for (final item in items) {
      final date = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      final key = date == today
          ? l10n.notifications_today
          : date == yesterday
              ? l10n.notifications_yesterday
              : '${item.createdAt.day}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.year}';

      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped;
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              AppIcons.notification,
              size: 50,
              color: AppColors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notifications_empty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              AppIcons.notification,
              size: 50,
              color: AppColors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notifications_categoryDisabled,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMessageCard extends StatelessWidget {
  const _CategoryMessageCard({
    required this.notification,
  });

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isRead = notification.isRead;
    final senderColor = isLight
        ? AppColors.primary.withValues(alpha: 0.14)
        : AppColors.primary.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: senderColor,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              notification.category.icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isRead
                    ? (isLight
                        ? AppColors.grey.withValues(alpha: 0.09)
                        : const Color(0xFF1F1F1F))
                    : AppColors.primary.withValues(alpha: isLight ? 0.08 : 0.16),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: isRead
                      ? (isLight
                          ? AppColors.grey.withValues(alpha: 0.2)
                          : const Color(0xFF2A2A2A))
                      : AppColors.primary.withValues(alpha: 0.34),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.category.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color:
                          isRead ? AppColors.grey : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime createdAt) {
    final hh = createdAt.hour.toString().padLeft(2, '0');
    final mm = createdAt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
