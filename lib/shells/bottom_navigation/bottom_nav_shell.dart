import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/notification_deep_link_handler.dart';
import '../../core/services/pending_notification_service.dart';
import '../../features/notifications/domain/entities/notification_item.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/notifications/presentation/widgets/in_app_notification_banner.dart';

/// Bottom navigation shell — 3 tabs: Home | Access | Hub.
///
/// All tabs are kept mounted (IndexedStack) so state and scroll positions
/// survive tab switches without any rebuilds.
///
/// Manages:
///  • In-app foreground notification banner overlay (auto-dismissed after 4 s).
///  • Background notification routing: subscribes to [PendingNotificationService.onPending]
///    and switches to the Notifications tab + triggers the detail sheet.
///  • Terminated-app notification routing: polls [PendingNotificationService.consume]
///    in a postFrameCallback once mounted.
///  • Local notification tap routing: listens to [FCMService.onDeepLink] and pushes
///    the route directly (no detail sheet — only a route string is available).
class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  StreamSubscription<NotificationItem>? _bannerSub;
  StreamSubscription<PendingNotificationPayload>? _pendingSub;
  StreamSubscription<String>? _pendingRouteSub;
  StreamSubscription<String?>? _deepLinkSub;
  NotificationItem? _bannerItem;
  Timer? _bannerTimer;

  // No notifications tab — notifications open as a push route from the AppBar bell.

  @override
  void initState() {
    super.initState();
    _bannerSub = FCMService.instance.onForegroundItem.listen(_onForegroundItem);
    _pendingSub =
        PendingNotificationService.instance.onPending.listen(_onPendingNotification);
    _pendingRouteSub =
        PendingNotificationService.instance.onPendingRoute.listen(_onPendingRoute);
    _deepLinkSub = FCMService.instance.onDeepLink.listen(_onDeepLink);
    // Terminated-app path: FCMService runs before this widget is mounted;
    // the payload is stored in PendingNotificationService._pending.
    // We consume it here once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingNotification());
  }

  @override
  void dispose() {
    _bannerSub?.cancel();
    _pendingSub?.cancel();
    _pendingRouteSub?.cancel();
    _deepLinkSub?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ── Foreground in-app banner ──────────────────────────────────────────────

  void _onForegroundItem(NotificationItem item) {
    if (!mounted) return;

    _bannerTimer?.cancel();
    setState(() => _bannerItem = item);
    _bannerTimer = Timer(const Duration(seconds: 4), _dismissBanner);
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerItem = null);
  }

  void _onBannerTap() {
    // Capture the item before dismiss clears _bannerItem.
    final item = _bannerItem;
    _dismissBanner();
    if (item == null) return;
    // Route through the Notifications tab + detail sheet so the user always
    // lands in the notification feed first (fintech UX pattern).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleNotificationPayload(
          PendingNotificationPayload(item: item, actionRoute: item.actionRoute),
        );
      }
    });
  }

  // ── Background / terminated notification routing ──────────────────────────

  /// Background path: shell IS mounted when the user taps a notification.
  /// [PendingNotificationService.onPending] fires immediately.
  void _onPendingNotification(PendingNotificationPayload payload) {
    if (!mounted) return;
    // Consume so the postFrameCallback poll does not double-handle the same payload.
    PendingNotificationService.instance.consume();
    _handleNotificationPayload(payload);
  }

  /// Terminated path: shell just mounted — poll the cache for a stored payload.
  void _checkPendingNotification() {
    final payload = PendingNotificationService.instance.consume();
    if (payload != null && mounted) _handleNotificationPayload(payload);

    final route = PendingNotificationService.instance.consumeRoute();
    if (route != null && mounted) _onDeepLink(route);
  }

  /// Local notification tap from a terminated app, stored during service init.
  /// Stream path — init finished while the shell was already mounted.
  void _onPendingRoute(String route) {
    if (!mounted) return;
    // Consume so the postFrameCallback poll does not double-handle it.
    PendingNotificationService.instance.consumeRoute();
    _onDeepLink(route);
  }

  /// Push to the Notifications page and signal it to open the detail sheet.
  void _handleNotificationPayload(PendingNotificationPayload payload) {
    if (!mounted) return;
    ref.read(notificationsProvider.notifier).markRead(payload.item.id);
    context.push(AppRoutes.notifications);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingNotificationOpenProvider.notifier).state = payload.item;
    });
  }

  /// Local notification tap path: only a route string is available
  /// (flutter_local_notifications payload). Navigate directly without a detail sheet.
  void _onDeepLink(String? route) {
    if (!mounted || route == null || route.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationDeepLinkHandler.handle(context, route);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          widget.navigationShell.goBranch(0, initialLocation: false);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            widget.navigationShell,
            if (_bannerItem != null)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: InAppNotificationBanner(
                  key: ValueKey(_bannerItem!.id),
                  item: _bannerItem!,
                  onDismiss: _dismissBanner,
                  onTap: _onBannerTap,
                ),
              ),
          ],
        ),
        bottomNavigationBar: HomeNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            const tabNames = ['Home', 'Access', 'Hub'];
            AnalyticsService.instance.trackBottomTabChanged(
              fromIndex: widget.navigationShell.currentIndex,
              toIndex: index,
              toTabName: tabNames[index],
            );
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          items: [
            HomeNavItem(icon: AppIcons.home, label: l10n.bottomNav_home),
            HomeNavItem(icon: AppIcons.lockOpen, label: l10n.bottomNav_access),
            HomeNavItem(icon: AppIcons.hub, label: l10n.bottomNav_hub),
          ],
        ),
      ),
    );
  }
}

// ── Private nav bar + item ─────────────────────────────────────────────────────

class HomeNavItem {
  const HomeNavItem({required this.icon, required this.label});
  final AppIconData icon;
  final String label;
}

class HomeNavBar extends StatelessWidget {
  const HomeNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeNavItem> items;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight ? AppColors.white : const Color(0xFF1F1F1F);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: HomeShadows.navBar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    isActive: i == currentIndex,
                    isLight: isLight,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.isLight,
    required this.onTap,
  });

  final HomeNavItem item;
  final bool isActive;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppColors.primary : AppColors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AppIcon(item.icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: iconColor,
              fontFamily: 'Geist',
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
