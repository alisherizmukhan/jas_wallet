import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/notification_deep_link_handler.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../social_meal/providers/meal_schedule_provider.dart';
import '../../../social_meal/providers/svc_meal_provider.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_detail_sheet.dart';

// ── Feed filter ───────────────────────────────────────────────────────────────

enum _FeedFilter { all, unread }

// ── Page ──────────────────────────────────────────────────────────────────────

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  _FeedFilter _filter = _FeedFilter.all;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The page is kept alive across tab switches (wantKeepAlive), so simply
  // returning to an already-open Notifications tab doesn't rebuild it. A
  // notification that arrived while the app was backgrounded only reaches
  // the feed once the app resumes (see firebaseMessagingBackgroundHandler in
  // fcm_service.dart), so reload here — otherwise it stays invisible until
  // the user thinks to pull-to-refresh manually.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  /// SVC meal and campus event reminders are local `zonedSchedule` alarms —
  /// they display their own system notification the moment they fire, but
  /// nothing writes them into this feed until their owning scheduler's next
  /// `resync()` runs `_deliverPastDueToFeed` (see MealReminderScheduler /
  /// EventReminderScheduler). That normally only happens when the SVC or
  /// Events page itself reloads, so a reminder that already fired stays
  /// invisible here — and unreachable by pulling to refresh — until the
  /// user happens to visit one of those pages first. Nudge both schedulers
  /// directly before reloading so this page is a reliable single place to
  /// see every category (general, SVC meals, events) without that detour.
  Future<void> _reload() async {
    // Only members ever get meal reminders scheduled in the first place —
    // gating here avoids creating mealScheduleProvider (and its network
    // fetch) for every non-member who simply opens this page, matching the
    // "SVC section (members only)" gating used everywhere else in the app.
    if (ref.read(svcMealProvider).isMember) {
      ref.read(mealScheduleProvider.notifier).resyncRemindersNow();
    }
    ref.read(eventsProvider.notifier).resyncRemindersNow();
    await ref.read(notificationsProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Background/terminated tap: BottomNavShell sets this provider; we open
    // the detail sheet once and immediately clear the signal.
    ref.listen<NotificationItem?>(pendingNotificationOpenProvider, (_, item) {
      if (item == null) return;
      ref.read(pendingNotificationOpenProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDetail(context, ref, item);
      });
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.notifications_title,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.notificationsSettings),
            padding: const EdgeInsets.only(right: 12),
            constraints: const BoxConstraints(),
            icon: AppIcon(
              AppIcons.settings,
              size: 22,
              color: isLight ? AppColors.iconGrey : AppColors.white,
            ),
            tooltip: l10n.notifications_settings,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          return ref.watch(notificationsProvider).when(
            loading: () => const _NotificationsSkeleton(),
            error: (e, _) => _ErrorState(message: '$e'),
            data: (items) {
              final filtered = _applyFilter(items);
              final grouped = _groupByDate(filtered, l10n);

              return Column(
                children: [
                  _FilterBar(
                    filter: _filter,
                    unreadCount:
                        items.where((n) => !n.isRead).length,
                    isLight: isLight,
                    onFilterChanged: (f) {
                      AnalyticsService.instance.trackNotificationsFilterChanged(
                        filter: f == _FeedFilter.unread ? 'unread' : 'all',
                      );
                      setState(() => _filter = f);
                    },
                    onMarkAllRead: items.any((n) => !n.isRead)
                        ? () {
                            AnalyticsService.instance
                                .trackNotificationsMarkAllReadClicked();
                            ref
                                .read(notificationsProvider.notifier)
                                .markAllRead();
                          }
                        : null,
                    l10n: l10n,
                  ),
                  Expanded(
                    // Always wrapped in RefreshIndicator — including the empty
                    // state — so pull-to-refresh works even before the first
                    // notification has ever landed (AlwaysScrollableScrollPhysics
                    // lets the drag register even when content doesn't fill the
                    // viewport, which a bare Center() never allowed).
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _reload,
                      child: grouped.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.65,
                                  child: _EmptyState(filter: _filter, l10n: l10n),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 32),
                              itemCount: grouped.length,
                              itemBuilder: (ctx, i) {
                                final entry = grouped[i];
                                if (entry is _DateHeader) {
                                  return _DateSectionHeader(label: entry.label);
                                }
                                final item = (entry as _ItemEntry).item;
                                return _NotificationRow(
                                  // Without a key, ListView.builder matches
                                  // rows by list position, not identity —
                                  // after a delete, the row State object
                                  // (and its now-fully-collapsed dismiss
                                  // AnimationController) gets reused for
                                  // whichever item shifted up into that
                                  // slot, so it renders at size/opacity 0
                                  // until something forces a full rebuild
                                  // (e.g. reopening the page). Keying by the
                                  // notification's own id ties each row's
                                  // State to that specific notification, so
                                  // deleting one disposes only its own
                                  // (collapsed) row and every row below it
                                  // keeps its own untouched, fully-visible
                                  // state as it shifts up.
                                  key: ValueKey(item.id),
                                  item: item,
                                  isLight: isLight,
                                  onTap: () => _openDetail(context, ref, item),
                                  onDelete: () {
                                    AnalyticsService.instance
                                        .trackNotificationDeletedFromList(
                                      notificationId: item.id,
                                      category: item.category.name,
                                    );
                                    ref
                                        .read(notificationsProvider.notifier)
                                        .deleteNotification(item.id);
                                  },
                                  l10n: l10n,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    final sorted = List<NotificationItem>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _filter == _FeedFilter.unread
        ? sorted.where((n) => !n.isRead).toList()
        : sorted;
  }

  // ── Date grouping ──────────────────────────────────────────────────────────

  List<Object> _groupByDate(
      List<NotificationItem> items, AppLocalizations l10n) {
    if (items.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <Object>[];
    String? currentBucket;

    for (final item in items) {
      final d = item.createdAt;
      final itemDay = DateTime(d.year, d.month, d.day);
      final String bucket;

      if (itemDay == today) {
        bucket = l10n.notifications_today;
      } else if (itemDay == yesterday) {
        bucket = l10n.notifications_yesterday;
      } else {
        bucket = l10n.common_earlier;
      }

      if (bucket != currentBucket) {
        result.add(_DateHeader(bucket));
        currentBucket = bucket;
      }
      result.add(_ItemEntry(item));
    }
    return result;
  }

  // ── Open detail ────────────────────────────────────────────────────────────

  void _openDetail(BuildContext ctx, WidgetRef ref, NotificationItem item) {
    AnalyticsService.instance.trackNotificationOpenedFromList(
      notificationId: item.id,
      category: item.category.name,
      wasUnread: !item.isRead,
    );
    if (!item.isRead) {
      ref.read(notificationsProvider.notifier).markRead(item.id);
    }

    final l10n = AppLocalizations.of(ctx) ?? lookupAppLocalizations(const Locale('en'));
    final effectiveRoute = _effectiveRoute(item);

    // Event reminders navigate straight to the event details page — the
    // notification is just a pointer to the event, so a detail sheet with
    // the same one-line text in between would only add a step.
    if (item.category == NotificationCategory.events && effectiveRoute != null) {
      ctx.push(effectiveRoute);
      return;
    }

    final label = effectiveRoute != null ? _actionLabel(item, l10n) : null;

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationDetailSheet(
        notification: item,
        actionLabel: label,
        onOpen: effectiveRoute != null
            ? () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ctx.mounted) ctx.push(effectiveRoute);
                });
              }
            : null,
      ),
    );
  }

  /// Returns the resolved route for this notification's action button.
  ///
  /// SVC always routes to the QR scan page — the actual user action is
  /// showing their QR code at the canteen, not viewing the dashboard.
  String? _effectiveRoute(NotificationItem item) {
    final raw = item.actionRoute;
    if (raw == null) return null;
    if (item.category == NotificationCategory.svc) return AppRoutes.svcQrScan;
    return NotificationDeepLinkHandler.resolve(raw);
  }

  /// Returns a contextual action label for the notification detail sheet.
  String _actionLabel(NotificationItem item, AppLocalizations l10n) {
    // Route-based override takes priority (e.g. clubs route inside social category)
    final route = item.actionRoute?.toLowerCase() ?? '';
    if (route.contains('club')) return l10n.notif_action_viewClub;

    switch (item.category) {
      case NotificationCategory.svc:
        return l10n.notif_action_showQr;
      case NotificationCategory.access:
        return l10n.notif_action_openAccess;
      case NotificationCategory.news:
        return l10n.notif_action_readMore;
      case NotificationCategory.general:
      case NotificationCategory.events:
      case NotificationCategory.orientation:
        return l10n.notifications_openScreen;
    }
  }
}

// ── Data model for list entries ───────────────────────────────────────────────

class _DateHeader {
  const _DateHeader(this.label);
  final String label;
}

class _ItemEntry {
  const _ItemEntry(this.item);
  final NotificationItem item;
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.unreadCount,
    required this.isLight,
    required this.onFilterChanged,
    required this.onMarkAllRead,
    required this.l10n,
  });

  final _FeedFilter filter;
  final int unreadCount;
  final bool isLight;
  final ValueChanged<_FeedFilter> onFilterChanged;
  final VoidCallback? onMarkAllRead;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? AppColors.borderGrey
                : AppColors.borderDark,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.notifications_filterAll,
            selected: filter == _FeedFilter.all,
            onTap: () => onFilterChanged(_FeedFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.notifications_filterUnread,
            selected: filter == _FeedFilter.unread,
            badge: unreadCount > 0 ? unreadCount : null,
            onTap: () => onFilterChanged(_FeedFilter.unread),
          ),
          Spacer(),
          if (onMarkAllRead != null)
            GestureDetector(
              onTap: onMarkAllRead,
              child: Row(
                children: [
                  AppIcon(AppIcons.doneAll, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    l10n.notifications_markAllRead,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isLight
                  ? AppColors.fieldBackground
                  : const Color(0xFF2C2C2E)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isLight ? AppColors.textColor : AppColors.white),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Date section header ───────────────────────────────────────────────────────

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.grey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Individual notification row ───────────────────────────────────────────────
//
// Wraps content in SizeTransition + FadeTransition so that when the delete
// action is tapped: (1) the card fades out over 180ms, (2) its height slot
// collapses over the remaining 100ms, pulling surrounding rows up smoothly.
// The animation completes BEFORE `onDelete()` fires, preventing any list jump.

class _NotificationRow extends StatefulWidget {
  const _NotificationRow({
    super.key,
    required this.item,
    required this.isLight,
    required this.onTap,
    required this.onDelete,
    required this.l10n,
  });

  final NotificationItem item;
  final bool isLight;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final AppLocalizations l10n;

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // Fade: 0→1 opacity reversed → 1→0 (card disappears quickly first)
  late final Animation<double> _fade;
  // Size: 1→0 height (space collapses after fade begins)
  late final Animation<double> _size;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // Fade completes at 65% of total duration (182ms) for snappy disappearance.
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );
    // Height collapse starts at 35% and finishes at 100% for a natural lift.
    _size = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
      ),
    );
    _ctrl.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    // `widget.onDelete()` calls `deleteNotification(id)` → provider rebuild.
    // At this point height is already 0, so the list removes the slot silently.
    if (status == AnimationStatus.completed && mounted) {
      widget.onDelete();
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onAnimationStatus);
    _ctrl.dispose();
    super.dispose();
  }

  /// Plays the exit animation once, then calls `onDelete` on completion.
  void _startDismiss() {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = widget.item.category;
    final isUnread = !widget.item.isRead;

    // SizeTransition is outermost: controls the list height slot.
    // FadeTransition is inner: fades the visual card without affecting layout.
    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fade,
        child: Slidable(
          key: ValueKey(widget.item.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.20,
            children: [
              CustomSlidableAction(
                // Route through _startDismiss instead of calling onDelete
                // directly — animation plays first, then delete fires.
                onPressed: (_) => _startDismiss(),
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(AppIcons.delete, size: 22),
                    const SizedBox(height: 3),
                    Text(
                      widget.l10n.common_delete,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Disable tap during dismiss to prevent navigation glitches.
              onTap: _dismissing ? null : widget.onTap,
              child: Container(
                color: isUnread
                    ? (widget.isLight
                        ? AppColors.primary.withValues(alpha: 0.03)
                        : AppColors.primary.withValues(alpha: 0.06))
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category icon badge
                    Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AppIcon(cat.icon, color: cat.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Category label
                              Text(
                                cat.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cat.color,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const Spacer(),
                              // Timestamp
                              Text(
                                _formatTime(widget.item.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.grey,
                                ),
                              ),
                              SizedBox(width: 8),
                              // Unread indicator
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: isUnread
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.item.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return widget.l10n.common_now;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.l10n});
  final _FeedFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const AppIcon(
                AppIcons.notification,
                size: 32,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filter == _FeedFilter.unread
                  ? l10n.notifications_allCaughtUp
                  : l10n.notifications_empty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (filter == _FeedFilter.unread) ...[
              const SizedBox(height: 6),
              Text(
                l10n.notifications_noUnread,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}

// ── Notifications skeleton ────────────────────────────────────────────────────
//
// Mirrors the visual structure of _NotificationRow so the layout does not
// jump when real data arrives: 42 px icon badge + three text lines on the right.

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final shimmer = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final shimmerLight = isLight ? Colors.grey.shade100 : Colors.grey.shade700;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: shimmerLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
