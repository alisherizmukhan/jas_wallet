import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/app_update_decision.dart';
import '../../domain/entities/app_update_status.dart';
import '../pages/required_update_page.dart';
import '../providers/app_update_provider.dart';
import 'optional_update_sheet.dart';

/// Mount once, at the top of the widget tree — see `lib/main.dart`, inside
/// `MaterialApp.router`'s `builder`, wrapping everything else (including
/// [PinUnlockOverlay]) so a required update takes priority over the PIN
/// lock screen too.
///
/// - `requiredUpdate`: replaces [child] entirely with [RequiredUpdatePage].
///   Nothing behind it is reachable — no back button, no dismiss.
/// - `optionalUpdate`: shows [showOptionalUpdateSheet] once per app
///   session, then lets [child] render underneath as normal.
/// - anything else: pure pass-through.
///
/// ── Why `router.routerDelegate.navigatorKey.currentContext` ──────────────
/// This widget's own [BuildContext] sits in `MaterialApp.router`'s
/// `builder` callback, which is an ANCESTOR of GoRouter's Navigator, not a
/// descendant — `showModalBottomSheet(context: context)` from here would
/// fail to find a Navigator. GoRouter always owns a `navigatorKey`
/// (auto-created if none is passed to its constructor); its
/// `.currentContext` is a valid Navigator-descendant context, which is
/// exactly what a globally-triggered bottom sheet needs. The alternative —
/// a widget inside the routed tree — doesn't work either, since routes like
/// welcome/onboarding mount before any authenticated shell does, and the
/// update check must apply there too.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  /// Edge-trigger guard — the optional sheet is offered at most once per
  /// app session, even if the decision is re-evaluated later (e.g. a
  /// future foreground recheck).
  bool _optionalSheetOffered = false;

  /// Re-entrancy guard — prevents two overlapping `showModalBottomSheet`
  /// calls if the state notifies more than once in quick succession.
  bool _isShowingSheet = false;

  void _maybeShowOptionalSheet(AppUpdateDecision decision) {
    if (_optionalSheetOffered || _isShowingSheet) return;
    _optionalSheetOffered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      final context = router.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;

      _isShowingSheet = true;
      try {
        await showOptionalUpdateSheet(context: context, ref: ref, decision: decision);
      } finally {
        _isShowingSheet = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final decision = ref.watch(appUpdateStateProvider);

    ref.listen<AppUpdateDecision>(appUpdateStateProvider, (previous, next) {
      if (next.status == AppUpdateStatus.optionalUpdate) {
        _maybeShowOptionalSheet(next);
      }
    });

    if (decision.status == AppUpdateStatus.requiredUpdate) {
      return RequiredUpdatePage(decision: decision);
    }

    return widget.child;
  }
}
