import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../theme/orientation_brand.dart';


/// Persistent bottom-nav shell for Orientation Week — mirrors the main app's
/// `BottomNavShell`, so the five tabs (Home · Challenges · Bingo · Photo
/// Quest · Rewards) all keep the same nav bar and their own state across tab
/// switches (`StatefulShellRoute.indexedStack`).
///
/// Unlike the main shell, this one is *pushed* onto the root navigator from
/// Hub, so returning to Hub is a normal pop: on the Home tab the pop is
/// allowed through (→ Hub); on any other tab it's intercepted and routed
/// back to Home first, matching the main shell's back behaviour.
class OrientationNavShell extends StatelessWidget {
  const OrientationNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = navigationShell.currentIndex;

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (index != 0) navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: FeatureStyle.pageBackground,
        body: navigationShell,
        bottomNavigationBar: FeatureBottomNav(
          currentIndex: index,
          accent: OrientationBrand.accent,
          items: [
            FeatureNavItem(icon: AppIcons.grid, label: l10n.orientation_tab_overview, onTap: () => _goBranch(0)),
            FeatureNavItem(icon: AppIcons.target, label: l10n.orientation_tab_challenges, onTap: () => _goBranch(1)),
            FeatureNavItem(icon: AppIcons.tasks, label: l10n.orientation_tab_bingo, onTap: () => _goBranch(2)),
            FeatureNavItem(icon: AppIcons.gift, label: l10n.orientation_tab_rewards, onTap: () => _goBranch(3)),
          ],
        ),
      ),
    );
  }
}
