import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../theme/orientation_brand.dart';

/// The one app bar every Orientation Week page uses.
///
/// Two things it exists to guarantee:
///
/// 1. **Identical chrome.** Same title type, same back button, no divider,
///    same balance pill in the same place — so moving between the five pages
///    never shifts the header.
/// 2. **One token balance, always current.** Each page used to read the
///    balance from whichever provider it happened to own: Bingo, Challenges
///    and Photo Quest read the dashboard, while Rewards read its own
///    `OrientationRewardsState.tokens` — a copy taken at its last load. Earn
///    tokens in Bingo, open Rewards, and the pill showed the old number until
///    something refreshed it. Here the pill has exactly one source (the
///    dashboard), and entering any page refreshes it, so the number a student
///    sees is the same on every screen.
class OrientationAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const OrientationAppBar({
    super.key,
    required this.title,
    this.showTokens = true,
    this.isShellRoot = false,
    this.onBackPressed,
    this.trailing,
  });

  /// True on the five tabbed pages (Overview · Challenges · Bingo · Photo
  /// Quest · Rewards). Their back button leaves Orientation Week entirely and
  /// returns to Hub — see [closeToHub] for why they cannot just pop.
  final bool isShellRoot;

  final String title;

  /// The balance pill. Hidden on pages where a balance is meaningless (a
  /// reward's own detail page, redemption history).
  final bool showTokens;

  /// Defaults to popping the current route. Shell roots pass a handler that
  /// pops the root navigator instead, closing Orientation Week back to Hub.
  final VoidCallback? onBackPressed;

  /// Optional extra action rendered before the balance pill.
  final Widget? trailing;

  /// Leaves Orientation Week and lands back on Hub, from any of the five tabs.
  ///
  /// Deliberately `pop`, not `maybePop`. [OrientationNavShell] wraps the shell
  /// in a `PopScope` with `canPop: index == 0`, which exists so the Android
  /// system back button walks a non-Overview tab back to Overview first. But
  /// `maybePop` honours that same `PopScope` — so the app-bar back button on
  /// Challenges, Bingo, Photo Quest or Rewards was being swallowed and turned
  /// into a tab switch, which reads as "the back button does nothing".
  /// `pop` bypasses the scope, which is right here: the header's back arrow
  /// means *leave this feature*, not *go up one tab*.
  ///
  /// The `go` fallback covers arriving by a route that replaced the stack
  /// rather than pushing onto it — a notification tap or deep link — where
  /// there is no entry to pop and the student would otherwise be trapped.
  static void closeToHub(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    GoRouter.of(context).go(AppRoutes.hub);
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  ConsumerState<OrientationAppBar> createState() => _OrientationAppBarState();
}

class _OrientationAppBarState extends ConsumerState<OrientationAppBar> {
  @override
  void initState() {
    super.initState();
    // Refresh on entry rather than trusting whatever the last page left
    // behind. `load()` keeps the previous dashboard in state while it runs
    // (see OrientationDashboardState.copyWith), so the pill shows the old
    // number until the new one lands instead of flashing empty.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(orientationDashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(
      orientationDashboardProvider.select((s) => s.dashboard?.tokens ?? 0),
    );

    return AppAppBar(
      showBackButton: true,
      showDivider: false,
      onBackPressed: widget.onBackPressed ??
          (widget.isShellRoot ? () => OrientationAppBar.closeToHub(context) : null),
      titleWidget: Text(widget.title, style: FeatureStyle.navTitle),
      actions: [
        if (widget.trailing != null) Center(child: widget.trailing!),
        if (widget.showTokens)
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Center(
              child: FeatureTokenPill(
                amount: tokens,
                semanticsLabel: AppLocalizations.of(context)!.orientation_total_tokens,
                accent: OrientationBrand.accent,
                icon: AppIcons.tokenAdsl,
              ),
            ),
          )
        else
          const SizedBox(width: 8),
      ],
    );
  }
}
