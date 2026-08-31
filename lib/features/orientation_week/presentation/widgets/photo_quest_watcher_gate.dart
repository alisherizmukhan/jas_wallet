import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../config/orientation_config.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/notification_channel_config.dart';
import '../../../../core/services/notification_storage_service.dart';
import '../../../notifications/domain/entities/notification_item.dart';
import '../../../notifications/presentation/widgets/in_app_notification_banner.dart';
import '../../data/services/photo_quest_status_store.dart';
import '../../domain/entities/photo_mission.dart';
import '../../domain/entities/photo_quest_verdict.dart';
import '../providers/orientation_dashboard_provider.dart';
import '../providers/orientation_leaderboard_provider.dart';
import '../providers/orientation_photo_quests_provider.dart';

/// Watches Photo Quest submissions for a verdict that arrives *after* the
/// upload response.
///
/// A photo can sit in `review` for minutes or hours — the CV service hands the
/// grey zone to a human moderator, and missions with no CV task go straight to
/// one. The backend records the decision correctly, but nothing on the device
/// asks about it: the mission list is fetched when the Photo Quest page builds
/// and never again. So an approved photo looked "still pending" until the
/// student happened to pull-to-refresh, and the tokens appeared with no
/// explanation. This gate closes that loop.
///
/// Mount once, high in the tree (see `lib/main.dart`), so it keeps running
/// while the student is anywhere in the app — the whole point is to reach them
/// when they are *not* looking at Photo Quest.
///
/// ── Where the result is delivered ────────────────────────────────────────
///  • On a Photo Quest screen  → nothing extra; the page rebuilds itself.
///  • Elsewhere in the app     → an in-app banner.
///  • App backgrounded         → a system notification.
///
/// ── The one thing this cannot do ─────────────────────────────────────────
/// Once the OS suspends or kills the process, no Dart timer runs, so a verdict
/// that lands then is announced on next launch rather than the moment it
/// happens. Delivering it to a killed app requires the backend to send an FCM
/// push on moderation — the client half of that is already in place
/// ([FCMService] routes `action_route` payloads), so it is a server change
/// only.
class PhotoQuestWatcherGate extends ConsumerStatefulWidget {
  const PhotoQuestWatcherGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PhotoQuestWatcherGate> createState() => _PhotoQuestWatcherGateState();
}

class _PhotoQuestWatcherGateState extends ConsumerState<PhotoQuestWatcherGate>
    with WidgetsBindingObserver {
  /// Long enough not to hammer the API from every installed device, short
  /// enough that a moderator decision feels immediate to whoever is watching
  /// their phone waiting for it.
  static const Duration _pollInterval = Duration(seconds: 30);

  static const PhotoQuestStatusStore _store = PhotoQuestStatusStore();

  Timer? _timer;
  bool _isPolling = false;
  bool _isStarted = false;

  /// Watches the Photo Quest state for submissions entering review, so a photo
  /// the student just sent is baselined immediately rather than up to one poll
  /// later. Subscribed manually (not via `ref.listen` in `build`) because
  /// touching the provider before sign-in would fire its initial load against
  /// an unauthenticated session.
  ProviderSubscription<PhotoQuestState>? _stateSub;

  /// Statuses this device has already reacted to. `null` until the persisted
  /// snapshot has loaded — polling waits for it, because diffing against an
  /// empty map would silently swallow the first real transition.
  Map<String, MissionStatus>? _lastSeen;

  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Last localizations seen through a live navigator context — see [_announce].
  AppLocalizations? _cachedL10n;

  final List<NotificationItem> _bannerQueue = [];
  NotificationItem? _bannerItem;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    // Coming back is the highest-value moment to check: a decision may have
    // landed while the process was suspended and the timer was not firing.
    if (state == AppLifecycleState.resumed && _isStarted) unawaited(_poll());
  }

  // ── Lifecycle of the watcher itself ──────────────────────────────────────

  Future<void> _start() async {
    // Orientation Week is closed for the season — this watcher exists only
    // to poll its API, so once nothing there is reachable it must not run
    // at all, not even in the background for a student who never opens the
    // feature again.
    if (_isStarted || OrientationConfig.isClosed) return;
    _isStarted = true;
    _lastSeen = await _store.read();
    if (!mounted) return;
    _log('started — ${_lastSeen!.length} mission(s) in the saved snapshot, '
        'poll every ${_pollInterval.inSeconds}s');
    _stateSub ??= ref.listenManual(
      orientationPhotoQuestsProvider,
      (previous, next) => _baselinePending(next),
    );
    await _poll();
  }

  void _stop() {
    if (!_isStarted) return;
    _isStarted = false;
    _timer?.cancel();
    _timer = null;
    _stateSub?.close();
    _stateSub = null;
    _lastSeen = null;
    // The next student to sign in on this device starts from a clean slate.
    unawaited(_store.clear());
  }

  /// Records missions that have *entered* review, and starts polling for them.
  ///
  /// Closes a narrow but real gap: a verdict is only announced as a transition
  /// out of a pending state, and the snapshot was previously only written by
  /// [_poll]. A photo submitted and then decided before the next poll would
  /// therefore go from `available` straight to `completed` in the snapshot,
  /// match no transition, and be announced to nobody.
  ///
  /// Only ever writes pending statuses, never verdicts, so it can correct the
  /// baseline but can never swallow an announcement.
  void _baselinePending(PhotoQuestState state) {
    final lastSeen = _lastSeen;
    if (!_isStarted || lastSeen == null) return;

    var changed = false;
    for (final mission in state.missions) {
      if (isPhotoQuestPending(mission.status) && lastSeen[mission.id] != mission.status) {
        lastSeen[mission.id] = mission.status;
        changed = true;
      }
    }
    if (!changed) return;

    _log('baselined ${state.missions.where((m) => m.isPending).length} pending mission(s)');
    unawaited(_store.write(lastSeen));
    _syncTimer(hasPending: true);
  }

  /// Runs only while something is actually pending. A student with no photo in
  /// review costs zero requests.
  void _syncTimer({required bool hasPending}) {
    if (hasPending && _timer == null) {
      _timer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
    } else if (!hasPending && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  // ── Poll → diff → announce ───────────────────────────────────────────────

  Future<void> _poll() async {
    final lastSeen = _lastSeen;
    if (_isPolling || !_isStarted || lastSeen == null) return;
    // Covers the rare case of the close date passing mid-session, with the
    // watcher already running — stop rather than just skipping this one
    // poll, so the periodic timer (if any) doesn't fire again either.
    if (OrientationConfig.isClosed) {
      _stop();
      return;
    }
    _isPolling = true;
    try {
      await ref.read(orientationPhotoQuestsProvider.notifier).refreshSilently();
      if (!mounted || !_isStarted) return;

      final missions = ref.read(orientationPhotoQuestsProvider).missions;
      if (missions.isEmpty) {
        _log('poll returned no missions — is the student signed in?');
        return;
      }

      final changes = diffPhotoQuestVerdicts(lastSeen: lastSeen, missions: missions);
      final pendingNow = missions.where((m) => m.isPending).length;
      _log('poll: ${missions.length} mission(s), $pendingNow pending, '
          '${changes.length} new verdict(s)');

      _lastSeen = {for (final m in missions) m.id: m.status};
      await _store.write(_lastSeen!);

      if (changes.isNotEmpty && mounted) {
        // An approval moves the token balance, so the app-bar pill has to be
        // refetched or it keeps showing the pre-approval number.
        if (changes.any((c) => c.approved)) {
          unawaited(ref.read(orientationDashboardProvider.notifier).load());
          unawaited(ref.read(orientationLeaderboardProvider.notifier).load());
        }
        _announce(changes);
      }

      _syncTimer(hasPending: ref.read(orientationPhotoQuestsProvider).hasPendingReview);
    } finally {
      _isPolling = false;
    }
  }

  void _announce(List<PhotoQuestVerdict> changes) {
    // This widget sits in `MaterialApp.router`'s builder — an ancestor of the
    // Navigator, not a descendant — so it has no route of its own to inspect.
    // GoRouter's navigator key gives a context that does. Same reasoning as
    // [AppUpdateGate].
    final router = ref.read(routerProvider);
    final navigatorContext = router.routerDelegate.navigatorKey.currentContext;

    // Cached because the system-notification path must not depend on a live
    // context: once the app is detached the navigator's context can be gone,
    // and that is precisely when posting a notification matters most. The
    // cache is refreshed on every announce that does have a context, so it
    // tracks the student's chosen language.
    if (navigatorContext != null && navigatorContext.mounted) {
      _cachedL10n = AppLocalizations.of(navigatorContext) ?? _cachedL10n;
    }
    final l10n = _cachedL10n;
    if (l10n == null) {
      _log('no localizations available yet — dropping ${changes.length} verdict(s)');
      return;
    }

    final isForeground = _lifecycle == AppLifecycleState.resumed;
    final isOnPhotoQuest = router.routeInformationProvider.value.uri.path
        .startsWith(AppRoutes.orientationPhotoQuests);

    for (final change in changes) {
      final item = _itemFor(change, l10n);

      // Into the Notifications feed regardless of how it is surfaced live.
      // A banner is gone in four seconds and an OS notification is gone the
      // moment it is swiped, so without this the news that a photo was
      // rejected could be missed permanently.
      unawaited(_recordInFeed(item));

      if (!isForeground) {
        _log('system notification → ${change.mission.id} '
            '(${change.approved ? "approved" : "declined"}, lifecycle=${_lifecycle.name})');
        unawaited(
          LocalNotificationService.instance.showNotification(
            // Stable per mission, so a re-announce replaces rather than stacks.
            id: change.mission.id.hashCode,
            title: item.title,
            body: item.message,
            channelId: NotificationChannels.orientation,
            channelName: NotificationChannels.orientationName,
            payload: AppRoutes.orientationPhotoQuests,
          ),
        );
        continue;
      }

      // Already looking at the screen that shows this — the card updating in
      // place is the notification.
      if (isOnPhotoQuest) {
        _log('on Photo Quest — card update is the notification for ${change.mission.id}');
        continue;
      }

      _log('in-app banner → ${change.mission.id} '
          '(${change.approved ? "approved" : "declined"})');
      _enqueueBanner(item);
    }
  }

  /// The feed/banner/notification all describe the same event, so they are
  /// built from one [NotificationItem] rather than three parallel copies that
  /// could drift apart.
  ///
  /// The id is stable for a given verdict on a given submission, so the
  /// storage layer's own de-duplication swallows a repeat announcement (a
  /// remount re-reading the same snapshot, say) while still admitting the
  /// *next* verdict after a re-shoot — hence [PhotoMission.submissionCount]
  /// in the key rather than the mission id alone.
  NotificationItem _itemFor(PhotoQuestVerdict change, AppLocalizations l10n) {
    return NotificationItem(
      id: 'photo_quest_${change.mission.id}_'
          '${change.mission.submissionCount}_'
          '${change.approved ? 'approved' : 'declined'}',
      title: change.approved
          ? l10n.orientation_pq_notify_approved_title
          : l10n.orientation_pq_notify_declined_title,
      message: change.approved
          ? l10n.orientation_pq_notify_approved_body(
              change.mission.title,
              change.mission.rewardTokens,
            )
          : l10n.orientation_pq_notify_declined_body(change.mission.title),
      category: NotificationCategory.orientation,
      createdAt: DateTime.now(),
      actionRoute: AppRoutes.orientationPhotoQuests,
    );
  }

  Future<void> _recordInFeed(NotificationItem item) async {
    try {
      await NotificationStorageService.instance.add(item);
    } catch (e) {
      // The feed is the durable copy, not the delivery mechanism — a failure
      // here must never take down the notification the student is waiting for.
      _log('feed write failed for ${item.id}: $e');
    }
  }

  // ── In-app banner ────────────────────────────────────────────────────────

  /// Queued rather than replaced: two verdicts can land in the same poll (a
  /// photo approved and another rejected), and the second is not less
  /// important than the first.
  void _enqueueBanner(NotificationItem item) {
    _bannerQueue.add(item);
    if (_bannerItem == null) _showNextBanner();
  }

  void _showNextBanner() {
    _bannerTimer?.cancel();
    if (!mounted) return;
    if (_bannerQueue.isEmpty) {
      setState(() => _bannerItem = null);
      return;
    }
    setState(() => _bannerItem = _bannerQueue.removeAt(0));
    _bannerTimer = Timer(const Duration(seconds: 4), _showNextBanner);
  }

  void _onBannerTap() {
    final route = _bannerItem?.actionRoute;
    _showNextBanner();
    if (route == null) return;
    // `context.push` would look for a GoRouter above this widget and find
    // none — the router is below. Drive it directly instead.
    ref.read(routerProvider).push(route);
  }

  /// Debug-build tracing. The whole flow is timers and lifecycle transitions
  /// with no UI of its own until the moment it fires, so without this a failure
  /// is indistinguishable from "nothing happened yet".
  void _log(String message) {
    if (kDebugMode) debugPrint('[PhotoQuestWatcher] $message');
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately not `watch`ing the Photo Quest provider: reading it here
    // would build it (and fire its initial load) before the student has signed
    // in. It is only ever touched from inside `_poll`, behind this gate.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        unawaited(_start());
      } else if (previous?.status == AuthStatus.authenticated) {
        _stop();
      }
    });

    if (!_isStarted && ref.read(authProvider).status == AuthStatus.authenticated) {
      // Signed in already when this mounted (warm start / hot restart), so the
      // listener above will never fire for it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_start());
      });
    }

    // The banner is drawn *here*, above the router, rather than reusing
    // BottomNavShell's. The shell's banner lives inside its own Scaffold, so
    // any pushed route — Orientation Week included — covers it. A verdict has
    // to be visible wherever the student happens to be standing.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_bannerItem != null)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: InAppNotificationBanner(
              key: ValueKey(_bannerItem!.id),
              item: _bannerItem!,
              onDismiss: _showNextBanner,
              onTap: _onBannerTap,
            ),
          ),
      ],
    );
  }
}
