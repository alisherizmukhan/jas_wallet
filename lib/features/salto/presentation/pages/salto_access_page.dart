import 'dart:async';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';


import '../../../../core/routing/app_router.dart';
import '../../../tutorial/data/tutorial_service.dart';
import '../../../tutorial/domain/tutorial_content.dart';
import '../../../tutorial/domain/tutorial_ids.dart';
import '../../../tutorial/presentation/pages/tutorial_story_page.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/models/salto_mobile_status.dart';
import '../../data/repositories/salto_repository_impl.dart';
import '../providers/access_stats_provider.dart';
import '../providers/salto_activation_provider.dart';
import '../providers/salto_activation_readiness_provider.dart';
import '../providers/salto_provider.dart';
import '../providers/salto_readiness_provider.dart';
import '../providers/salto_student_card_provider.dart';
import '../widgets/salto_activation_prerequisites.dart';
import '../widgets/salto_card_scan_effect.dart';
import '../widgets/salto_student_card_widget.dart';

class SaltoAccessPage extends ConsumerStatefulWidget {
  const SaltoAccessPage({super.key});

  @override
  ConsumerState<SaltoAccessPage> createState() => _SaltoAccessPageState();
}

class _SaltoAccessPageState extends ConsumerState<SaltoAccessPage>
    with WidgetsBindingObserver {
  bool _isActivating = false;

  /// Prevents the auto-refresh from firing more than once per rejection event.
  /// Reset when the unlock state returns to idle.
  bool _autoRefreshTriggered = false;

  /// Set when the "Retry" tap that just armed the button back to "Open"
  /// happened while the key was in [SaltoUnlockState.rejected]. Consumed by
  /// the very next tap so it performs the same forced-key-refresh retry the
  /// single-tap flow used to run for a rejected key — only the click count
  /// changed, not which underlying operation eventually fires.
  bool _armedRetryNeedsKeyRefresh = false;

  /// Subscription for auto-refresh on rejected state. Cancelled in dispose().
  ProviderSubscription<SaltoUnlockState>? _unlockSub;

  /// How often the readiness indicator is re-evaluated while the app is in
  /// the foreground — cheap local state reads only (no BLE scan, no
  /// network in the common case), bounded to foreground so it costs
  /// nothing while backgrounded. This is what lets the Open button
  /// automatically re-enable when Bluetooth/permissions/connectivity
  /// change while the page is already open, without the user needing to
  /// leave and reopen it.
  static const _fastReadinessPollInterval = Duration(seconds: 3);

  /// Once readiness has been stable (unchanged) for
  /// [_stableTicksBeforeSlowdown] consecutive polls, the interval backs off
  /// to this — most Access page visits sit in a single steady state for
  /// most of the time they're open, so there's no need to keep polling
  /// native Bluetooth/permission state every 3 seconds indefinitely. Any
  /// observed change resets immediately back to [_fastReadinessPollInterval].
  static const _slowReadinessPollInterval = Duration(seconds: 8);
  static const _stableTicksBeforeSlowdown = 3;

  Duration _currentReadinessPollInterval = _fastReadinessPollInterval;
  int _stableReadinessTicks = 0;
  Timer? _readinessPollTimer;

  /// Whether the user was sent to system Settings from an activation
  /// prerequisite dialog (Bluetooth/Internet) on this visit — used only to
  /// log a precise "returned from settings" event on the next resume.
  bool _awaitingActivationSettingsReturn = false;

  /// Whether this page is the *currently visible* bottom-nav tab.
  ///
  /// The 3 bottom-nav tabs (Home/Access/Hub) all stay mounted at once via
  /// GoRouter's `StatefulShellRoute.indexedStack` — switching tabs never
  /// disposes this page, so [dispose]/[didChangeAppLifecycleState] alone
  /// are not enough to stop the readiness poll: without this check, a user
  /// sitting idle on Home or Hub would still have this page silently
  /// polling Bluetooth state every 3–8s in the background, indefinitely.
  /// GoRouter disables `TickerMode` for inactive branches specifically for
  /// cases like this — [didChangeDependencies] below tracks it.
  bool _isTabVisible = true;

  @override
  void initState() {
    super.initState();
    // Screen-view tracking for this page is already covered generically by
    // AnalyticsNavigationObserver (route name 'access' -> 'Salto Access')
    // — no separate "page opened" event needed here.
    final shouldShowTutorial =
        TutorialService.instance.shouldShowSync(TutorialIds.saltoAccess);
    if (shouldShowTutorial) {
      TutorialService.instance.markSeenSync(TutorialIds.saltoAccess);
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reset stale unlock state from a previous visit.
      ref.read(saltoUnlockProvider.notifier).reset();
      // Prewarm key using SaltoKeyManager — handles expiry, TTL, and
      // near-expiry silent refresh automatically.
      _primeDigitalKey();
      // Listen for rejected state and auto-refresh the key once.
      _unlockSub = ref.listenManual<SaltoUnlockState>(
        saltoUnlockProvider,
        _onUnlockStateChanged,
      );
      _isTabVisible = TickerMode.valuesOf(context).enabled;
      if (_isTabVisible) _startReadinessPolling();
      if (shouldShowTutorial) {
        final l10n = AppLocalizations.of(context)!;
        // Skip the fade when the system "reduce motion" preference is on —
        // the tutorial still opens, just instantly instead of animated.
        final reduceMotion = MediaQuery.of(context).disableAnimations;
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder<void>(
            opaque: true,
            transitionDuration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 300),
            pageBuilder: (ctx, animation, _) => FadeTransition(
              opacity: animation,
              child: TutorialStoryPage(
                tutorialId: TutorialIds.saltoAccess,
                slides: TutorialContent.saltoAccess(l10n),
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = TickerMode.valuesOf(context).enabled;
    if (isVisible == _isTabVisible) return;
    _isTabVisible = isVisible;
    if (isVisible) {
      // Tab became active again (user switched back to Access) — mirrors
      // the app-resume recovery path below, just triggered by tab
      // switching instead of the whole app backgrounding/foregrounding.
      _primeDigitalKey();
      ref.read(saltoReadinessProvider.notifier).refresh();
      ref.read(saltoActivationReadinessProvider.notifier).refresh();
      _startReadinessPolling();
    } else {
      _stopReadinessPolling();
    }
  }

  @override
  void dispose() {
    _stopReadinessPolling();
    _unlockSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On foreground resume, re-prewarm the key silently so it's always
  /// fresh, force an immediate readiness re-check (Bluetooth/permissions
  /// may have changed while backgrounded — e.g. the user went to Settings
  /// and back), and resume the readiness poll. On backgrounding, stop the
  /// poll — it only needs to run while the app is actually visible.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SaltoAnalytics.instance.updateAppLifecycleState(state.name);
    if (state == AppLifecycleState.resumed) {
      SaltoAnalytics.instance.trackResumeRecovery();
      _primeDigitalKey();
      final returnedFromSettings = _awaitingActivationSettingsReturn;
      if (_awaitingActivationSettingsReturn) {
        _awaitingActivationSettingsReturn = false;
        unawaited(ref.read(saltoActivationProvider.notifier).logSettingsReturned());
        SaltoAnalytics.instance.trackUserReturnedFromSettings();
        switch (SaltoActivationPrerequisites.lastSettingsTypeOpened) {
          case 'bluetooth':
            SaltoAnalytics.instance.trackBluetoothSettingsReturned(flow: 'unlock');
          case 'network':
            SaltoAnalytics.instance.trackNetworkSettingsReturned();
        }
      }
      // Only resume the poll if this tab is actually the visible one —
      // the app can resume from background while the user was last on a
      // different bottom-nav tab; see [_isTabVisible] / [didChangeDependencies].
      if (_isTabVisible) {
        ref.read(saltoReadinessProvider.notifier).refresh();
        ref.read(saltoActivationReadinessProvider.notifier).refresh();
        _startReadinessPolling();
        if (returnedFromSettings) unawaited(_continueActivationAfterSettings());
      }
    } else {
      SaltoAnalytics.instance.trackBackgroundRecovery();
      _stopReadinessPolling();
    }
  }

  /// The auto-recovery a prerequisite promises when it sends the user to
  /// Settings: pick the flow back up on return rather than leaving them
  /// looking at an unchanged screen, wondering whether their tap registered.
  ///
  /// Only continues once readiness actually clears — coming back without
  /// having fixed anything would otherwise re-open the dialog they just
  /// dismissed. The destructive confirmation still gates activation, so this
  /// can never enable mobile access without an explicit tap.
  Future<void> _continueActivationAfterSettings() async {
    await ref.read(saltoActivationReadinessProvider.notifier).refresh();
    if (!mounted || _isActivating) return;
    if (!_requiresReactivation(ref.read(saltoStatusProvider).valueOrNull)) return;
    if (!ref.read(saltoActivationReadinessProvider).isReady) return;
    await _activateFromAccess(context, ref.read(saltoUnlockProvider.notifier));
  }

  void _startReadinessPolling({Duration interval = _fastReadinessPollInterval}) {
    _readinessPollTimer?.cancel();
    _currentReadinessPollInterval = interval;
    _stableReadinessTicks = 0;
    _readinessPollTimer = Timer.periodic(interval, (_) => _pollReadinessOnce());
  }

  void _stopReadinessPolling() {
    _readinessPollTimer?.cancel();
    _readinessPollTimer = null;
  }

  Future<void> _pollReadinessOnce() async {
    if (!mounted) return;
    final readinessBefore = ref.read(saltoReadinessProvider);
    final activationBefore = ref.read(saltoActivationReadinessProvider);

    await Future.wait([
      ref.read(saltoReadinessProvider.notifier).refresh(),
      ref.read(saltoActivationReadinessProvider.notifier).refresh(),
    ]);
    if (!mounted) return;

    final changed = ref.read(saltoReadinessProvider) != readinessBefore ||
        ref.read(saltoActivationReadinessProvider) != activationBefore;

    if (changed) {
      _stableReadinessTicks = 0;
      if (_currentReadinessPollInterval != _fastReadinessPollInterval) {
        _startReadinessPolling();
      }
      return;
    }

    _stableReadinessTicks++;
    if (_stableReadinessTicks >= _stableTicksBeforeSlowdown &&
        _currentReadinessPollInterval != _slowReadinessPollInterval) {
      _startReadinessPolling(interval: _slowReadinessPollInterval);
    }
  }

  void _onUnlockStateChanged(
    SaltoUnlockState? previous,
    SaltoUnlockState next,
  ) {
    if (next == SaltoUnlockState.idle) {
      _autoRefreshTriggered = false;
    }
    if (next == SaltoUnlockState.rejected && !_autoRefreshTriggered && mounted) {
      _autoRefreshTriggered = true;
      _silentRefreshAndRetry();
    }
  }

  /// Silently force-refreshes the SALTO key from the backend and retries
  /// the unlock. No toast on failure — user can tap the button manually.
  Future<void> _silentRefreshAndRetry() async {
    try {
      await ref.read(saltoUnlockProvider.notifier).refreshAndRetry();
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Prewarms the digital key using [SaltoKeyManager].
  ///
  /// - No cached key → fetches from backend.
  /// - Expired key → force-refreshes from backend.
  /// - Near-expiry key → background-refreshes silently.
  /// - Fresh key → no-op (already in in-memory cache).
  void _primeDigitalKey() {
    try {
      ref.read(saltoKeyManagerProvider).prewarm();
    } catch (_) {
      // Fire-and-forget — never block the UI.
    }
  }

  Future<void> _activateFromAccess(
    BuildContext context,
    SaltoUnlockNotifier notifier,
  ) async {
    // Defense-in-depth: the confirmation dialog below is non-dismissible
    // and its barrier already blocks the button underneath, but gating
    // here too guarantees "one tap = one activation attempt" even if that
    // ever changes.
    if (_isActivating) {
      SaltoAnalytics.instance.trackRapidMultipleTaps(tapContext: 'activation_button');
      return;
    }

    setState(() => _isActivating = true);
    SaltoAnalytics.instance.trackActivationButtonPressed();
    try {
      // Prerequisites run *before* the confirmation — see the matching
      // comment in SaltoActivationPage. Confirming a destructive switch and
      // only then being bounced to Settings threw the confirmation away.
      final prereq = await SaltoActivationPrerequisites.ensureReady(context, ref);
      if (prereq == SaltoPrerequisiteResult.wentToSettings) {
        _awaitingActivationSettingsReturn = true;
        return; // auto-recovery on resume — see didChangeAppLifecycleState
      }
      if (prereq == SaltoPrerequisiteResult.cancelled) return;
      if (!context.mounted) return;

      SaltoAnalytics.instance.trackActivationConfirmDialogOpened();
      final confirmed = await AppPremiumDialog.show(
        context: context,
        icon: AppIcons.phone,
        iconColor: const Color(0xFF007AFF),
        title: _activationConfirmTitle(context),
        description: _activationConfirmDescription(context),
        confirmText: _activationConfirmButton(context),
        cancelText: _cancelButton(context),
        // Disabling physical card access must never happen — or fail to
        // happen — from an accidental swipe-down or a barrier tap; the
        // user must land on an explicit Confirm/Cancel.
        isDismissible: false,
        enableDrag: false,
      );
      if (!confirmed) {
        SaltoAnalytics.instance.trackActivationCancelled();
        SaltoAnalytics.instance.trackUserCancelledActivation();
        return;
      }
      SaltoAnalytics.instance.trackActivationConfirmed();
      if (!context.mounted) return;

      final result = await ref.read(saltoActivationProvider.notifier).activate();
      if (result == null) {
        // Refused before the POST was ever sent (offline, or another attempt
        // already in flight), or sent but its outcome could not be confirmed
        // after a timeout — never silent.
        if (!context.mounted) return;
        final reason =
            ref.read(saltoActivationProvider.notifier).lastFailureReason;
        AppToast.showError(context, _activationGateMessage(context, reason));
        return;
      }

      notifier.reset();
      if (!context.mounted) return;
      if (result.message != null && result.message!.isNotEmpty) {
        AppToast.showInfo(context, result.message!);
      }

      await notifier.unlock();
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, _userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  /// Message for activation being refused *before* the POST was attempted
  /// — distinct from [_userFacingErrorMessage], which covers a POST that
  /// was actually sent and rejected/failed.
  String _activationGateMessage(
    BuildContext context,
    SaltoActivationFailureReason reason,
  ) {
    switch (reason) {
      case SaltoActivationFailureReason.internetUnavailable:
        return switch (_language(context)) {
          'ru' => 'Нет подключения к интернету. Подключитесь к интернету и попробуйте снова.',
          'kk' => 'Интернет байланысы жоқ. Интернетке қосылып, қайта көріңіз.',
          _ => 'No internet connection. Please connect to the internet and try again.',
        };
      case SaltoActivationFailureReason.alreadyActivating:
        return switch (_language(context)) {
          'ru' => 'Активация уже выполняется. Пожалуйста, подождите.',
          'kk' => 'Белсендіру әлдеқашан жүріп жатыр. Күте тұрыңыз.',
          _ => 'Activation is already in progress. Please wait.',
        };
      // Deliberately does not say "try again": the request may still be
      // completing on the server, and a second activation cancels the key the
      // first one is issuing.
      case SaltoActivationFailureReason.timedOutStillRunning:
        return switch (_language(context)) {
          'ru' => 'Активация занимает больше времени, чем обычно, и еще может завершиться. Подождите минуту и обновите экран — не нажимайте кнопку повторно.',
          'kk' => 'Белсендіру әдеттегіден ұзағырақ жүріп жатыр және әлі аяқталуы мүмкін. Бір минут күтіп, экранды жаңартыңыз — түймені қайта баспаңыз.',
          _ => 'This is taking longer than usual and may still be completing. Please wait a minute and refresh — do not tap again.',
        };
      case SaltoActivationFailureReason.backendRejected:
      case SaltoActivationFailureReason.unknown:
      case SaltoActivationFailureReason.none:
        return _genericErrorText(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final state = ref.watch(saltoUnlockProvider);
    final notifier = ref.read(saltoUnlockProvider.notifier);
    final readiness = ref.watch(saltoReadinessProvider);
    final statusAsync = ref.watch(saltoStatusProvider);
    final status = statusAsync.valueOrNull;
    final statusIsLoading = statusAsync.isLoading && status == null;
    final statusLoadFailed = statusAsync.hasError && status == null;

    final supported = Platform.isAndroid || Platform.isIOS;
    final activationRequired = _requiresReactivation(status);

    final Widget scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.saltoAccess_title,
        showBackButton: false,
        showDivider: false,
        actions: [
          _buildStatsButton(context),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildStatusCard(context, state, isLight, l10n, statusAsync),
              const SizedBox(height: 16),
              _buildMainButton(
                context,
                state,
                supported,
                notifier,
                l10n,
                status,
                activationRequired,
                statusIsLoading,
                statusLoadFailed,
                readiness,
              ),
              const SizedBox(height: 24),
              _buildHintSection(
                context,
                l10n,
                theme,
                status,
                activationRequired,
                statusIsLoading,
                statusLoadFailed,
                readiness,
                notifier.lastFailureReason,
              ),
              const SizedBox(height: 32),
              _buildFaqSection(context, theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
    return scaffold;
  }

  Widget _buildStatsButton(BuildContext context) {
    final totalAsync = ref.watch(totalAccessCountProvider);
    final count = totalAsync.valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.accessStats),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            AppIcon(AppIcons.statistics, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SaltoUnlockState state,
    bool isLight,
    AppLocalizations l10n,
    AsyncValue<SaltoMobileStatus> statusAsync,
  ) {
    final theme = Theme.of(context);
    final status = statusAsync.valueOrNull;

    // Resolve status label, icon, and colour for the badge below the card.
    String statusText;
    Color statusColor;
    AppIconData statusIcon;

    if (statusAsync.isLoading && status == null) {
      statusText = _checkingAccessText(context);
      statusColor = AppColors.grey;
      statusIcon = AppIcons.refresh;
    } else if (statusAsync.hasError && status == null) {
      statusText = _statusLoadErrorText(context);
      statusColor = AppColors.error;
      statusIcon = AppIcons.error;
    } else if (_requiresReactivation(status)) {
      statusText = _activationRequiredText(context, status);
      statusColor = AppColors.error;
      statusIcon = AppIcons.warning;
    } else {
      switch (state) {
        case SaltoUnlockState.idle:
          statusText = l10n.saltoAccess_ready;
          statusColor = AppColors.primary;
          statusIcon = AppIcons.lockOpen;
          break;
        case SaltoUnlockState.scanning:
          statusText = l10n.saltoAccess_scanning;
          statusColor = AppColors.primary;
          statusIcon = AppIcons.info;
          break;
        case SaltoUnlockState.connecting:
          statusText = l10n.saltoAccess_connecting;
          statusColor = AppColors.primary;
          statusIcon = AppIcons.info;
          break;
        case SaltoUnlockState.granted:
          statusText = l10n.saltoAccess_granted;
          statusColor = AppColors.green;
          statusIcon = AppIcons.check;
          break;
        case SaltoUnlockState.rejected:
          statusText = l10n.saltoAccess_rejected;
          statusColor = AppColors.red;
          statusIcon = AppIcons.close;
          break;
        case SaltoUnlockState.error:
          statusText = _unlockFailedText(context);
          statusColor = AppColors.grey;
          statusIcon = AppIcons.error;
          break;
        case SaltoUnlockState.noKey:
          statusText = l10n.saltoAccess_notConfigured;
          statusColor = AppColors.grey;
          statusIcon = AppIcons.info;
          break;
      }
    }

    // Animation flags.
    final isScanning =
        state == SaltoUnlockState.scanning ||
        state == SaltoUnlockState.connecting;
    final showResult =
        state == SaltoUnlockState.granted ||
        state == SaltoUnlockState.rejected;
    final resultColor = state == SaltoUnlockState.granted
        ? AppColors.green
        : state == SaltoUnlockState.rejected
            ? AppColors.red
            : null;

    // Card data from providers.
    final userAsync = ref.watch(userProvider);
    final cardState = ref.watch(saltoStudentCardProvider);
    final user = userAsync.valueOrNull;
    final cardReady = user != null && cardState.isLoaded;

    return Column(
      children: [
        // ── Student card with scan effect ──
        if (cardReady)
          SaltoCardScanEffect(
            isScanning: isScanning,
            showResult: showResult,
            resultColor: resultColor,
            child: SaltoStudentCard(
              firstName: user.firstName,
              lastName: user.lastName,
              studentId: (user.studentId?.trim().isNotEmpty ?? false)
                  ? user.studentId!.trim()
                  : user.id,
              avatarUrl: user.avatarUrl,
              design: cardState.selectedDesign,
              customDesignImagePath: cardState.customDesignImagePath,
              isNuStudent: (user.email?.trim().toLowerCase().endsWith('@nu.edu.kz') ?? false),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 1.586,
            child: Container(
              decoration: BoxDecoration(
                color: isLight
                    ? AppColors.fieldBackground
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                ),
              ),
              child: const Center(child: AppLoader()),
            ),
          ),

        const SizedBox(height: 14),

        // ── Compact status badge ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(statusIcon, size: 18, color: statusColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHintSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SaltoMobileStatus? status,
    bool activationRequired,
    bool statusIsLoading,
    bool statusLoadFailed,
    SaltoReadinessState readiness,
    SaltoFailureReason failureReason,
  ) {
    final unlockState = ref.watch(saltoUnlockProvider);

    // The readiness hint takes priority over the plain idle hint whenever
    // the button is disabled specifically because SALTO isn't ready yet —
    // but only while genuinely idle: an in-flight attempt already has its
    // own scanning/connecting copy, and activation/status-load are handled
    // by their own dedicated branches above this one.
    final showReadinessHint = unlockState == SaltoUnlockState.idle &&
        !statusIsLoading &&
        !statusLoadFailed &&
        !activationRequired &&
        !readiness.isReady &&
        readiness.issue != SaltoReadinessIssue.unlockInProgress &&
        readiness.issue != SaltoReadinessIssue.none;

    final specificSecondary = _specificSecondaryHint(context, failureReason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          statusIsLoading
              ? _statusLoadingHint(context)
              : statusLoadFailed
              ? _statusLoadHint(context)
              : activationRequired
              ? _activationHint(context, status)
              : showReadinessHint
              ? (_readinessHint(context, readiness.issue) ?? l10n.saltoAccess_hint)
              : unlockState == SaltoUnlockState.rejected
              ? _rejectedHint(context)
              : (unlockState == SaltoUnlockState.error
                    ? _unlockFailedHint(context)
                    : l10n.saltoAccess_hint),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          statusIsLoading
              ? _statusLoadingHintSecondary(context)
              : statusLoadFailed
              ? _statusLoadHintSecondary(context)
              : activationRequired
              ? _activationHintSecondary(context, status)
              : showReadinessHint
              ? (_readinessHintSecondary(context, readiness.issue) ??
                    l10n.saltoAccess_hintBluetooth)
              : unlockState == SaltoUnlockState.rejected
              ? _rejectedHintSecondary(context)
              : unlockState == SaltoUnlockState.noKey
              ? (specificSecondary ?? _noKeyHintSecondary(context))
              : (unlockState == SaltoUnlockState.error
                    ? (specificSecondary ?? _unlockFailedHintSecondary(context))
                    : l10n.saltoAccess_hintBluetooth),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.grey.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Readiness-specific hint text ──────────────────────────────────────────
  //
  // Shown proactively (before any tap) when the Open button is disabled
  // because SALTO isn't ready yet — replaces the previous behavior of
  // discovering the exact same conditions only after tapping and getting a
  // generic post-attempt error.

  String? _readinessHint(BuildContext context, SaltoReadinessIssue issue) {
    switch (issue) {
      case SaltoReadinessIssue.bluetoothOff:
        return switch (_language(context)) {
          'ru' => 'Bluetooth выключен',
          'kk' => 'Bluetooth өшірулі',
          _ => 'Bluetooth is off',
        };
      case SaltoReadinessIssue.bluetoothNotReady:
        return switch (_language(context)) {
          'ru' => 'Bluetooth еще не готов',
          'kk' => 'Bluetooth әлі дайын емес',
          _ => 'Bluetooth is not ready yet',
        };
      case SaltoReadinessIssue.bluetoothUnauthorized:
        return switch (_language(context)) {
          'ru' => 'Нет разрешения на Bluetooth',
          'kk' => 'Bluetooth рұқсаты жоқ',
          _ => 'Bluetooth permission is not authorized',
        };
      case SaltoReadinessIssue.bluetoothUnsupported:
        return switch (_language(context)) {
          'ru' => 'Это устройство не поддерживает Bluetooth',
          'kk' => 'Бұл құрылғы Bluetooth-ты қолдамайды',
          _ => 'This device does not support Bluetooth',
        };
      case SaltoReadinessIssue.permissionDenied:
        return switch (_language(context)) {
          'ru' => 'Нет разрешения Bluetooth',
          'kk' => 'Bluetooth рұқсаты жоқ',
          _ => 'Bluetooth permission is required',
        };
      case SaltoReadinessIssue.locationOff:
        return switch (_language(context)) {
          'ru' => 'Службы геолокации выключены',
          'kk' => 'Геолокация қызметтері өшірулі',
          _ => 'Location services are off',
        };
      case SaltoReadinessIssue.internetUnavailable:
        return switch (_language(context)) {
          'ru' => 'Нет подключения к интернету',
          'kk' => 'Интернет байланысы жоқ',
          _ => 'No internet connection',
        };
      case SaltoReadinessIssue.unsupportedPlatform:
        return switch (_language(context)) {
          'ru' => 'Устройство не поддерживается',
          'kk' => 'Құрылғыға қолдау көрсетілмейді',
          _ => 'This device is not supported',
        };
      case SaltoReadinessIssue.unlockInProgress:
      case SaltoReadinessIssue.none:
        return null;
    }
  }

  String? _readinessHintSecondary(BuildContext context, SaltoReadinessIssue issue) {
    switch (issue) {
      case SaltoReadinessIssue.bluetoothOff:
        return switch (_language(context)) {
          'ru' => 'Включите Bluetooth в настройках, чтобы открыть турникет.',
          'kk' => 'Турникетті ашу үшін баптауларда Bluetooth-ты қосыңыз.',
          _ => 'Turn on Bluetooth in Settings to unlock the turnstile.',
        };
      case SaltoReadinessIssue.bluetoothNotReady:
        return switch (_language(context)) {
          'ru' => 'Подождите пару секунд, пока Bluetooth включится.',
          'kk' => 'Bluetooth қосылып болғанша бірнеше секунд күтіңіз.',
          _ => 'Give it a moment while Bluetooth finishes turning on.',
        };
      case SaltoReadinessIssue.bluetoothUnauthorized:
        return switch (_language(context)) {
          'ru' => 'Разрешите доступ к Bluetooth в настройках устройства.',
          'kk' => 'Құрылғы баптауларында Bluetooth рұқсатын беріңіз.',
          _ => 'Allow Bluetooth access for this app in your device Settings.',
        };
      case SaltoReadinessIssue.bluetoothUnsupported:
        return switch (_language(context)) {
          'ru' => 'Турникет можно открыть только на устройстве с Bluetooth LE.',
          'kk' => 'Турникетті тек Bluetooth LE бар құрылғыда ашуға болады.',
          _ =>
            'The turnstile can only be unlocked from a device with Bluetooth LE.',
        };
      case SaltoReadinessIssue.permissionDenied:
        return switch (_language(context)) {
          'ru' => 'Разрешите Bluetooth (и Nearby devices на Android) в настройках приложения.',
          'kk' => 'Қолданба баптауларында Bluetooth (Android-та Nearby devices) рұқсатын беріңіз.',
          _ =>
            'Grant the Bluetooth (and Nearby devices, on Android) permission in this app\'s Settings.',
        };
      case SaltoReadinessIssue.locationOff:
        return switch (_language(context)) {
          'ru' => 'На этой версии Android для сканирования Bluetooth нужна геолокация.',
          'kk' => 'Осы Android нұсқасында Bluetooth сканерлеу үшін геолокация қажет.',
          _ => 'This Android version needs location services on for Bluetooth scanning.',
        };
      case SaltoReadinessIssue.internetUnavailable:
        return switch (_language(context)) {
          'ru' => 'Нужен интернет, чтобы получить ключ доступа в первый раз.',
          'kk' => 'Қолжетімділік кілтін алғаш алу үшін интернет қажет.',
          _ => 'You need a connection to fetch your access key for the first time.',
        };
      case SaltoReadinessIssue.unsupportedPlatform:
      case SaltoReadinessIssue.unlockInProgress:
      case SaltoReadinessIssue.none:
        return null;
    }
  }

  /// Specific secondary-hint override for a known [SaltoFailureReason] on
  /// the post-attempt `error`/`noKey` states — falls back to the existing
  /// generic secondary text (via the caller passing `null` through) for
  /// `none`/`unknown`/`rejected` (rejected already has its own dedicated
  /// copy).
  String? _specificSecondaryHint(BuildContext context, SaltoFailureReason reason) {
    switch (reason) {
      case SaltoFailureReason.permissionDenied:
        return _readinessHintSecondary(context, SaltoReadinessIssue.permissionDenied);
      case SaltoFailureReason.bluetoothOff:
        return _readinessHintSecondary(context, SaltoReadinessIssue.bluetoothOff);
      case SaltoFailureReason.bluetoothNotReady:
        return _readinessHintSecondary(context, SaltoReadinessIssue.bluetoothNotReady);
      case SaltoFailureReason.bluetoothUnauthorized:
        return _readinessHintSecondary(context, SaltoReadinessIssue.bluetoothUnauthorized);
      case SaltoFailureReason.bluetoothUnsupported:
        return _readinessHintSecondary(context, SaltoReadinessIssue.bluetoothUnsupported);
      case SaltoFailureReason.locationOff:
        return _readinessHintSecondary(context, SaltoReadinessIssue.locationOff);
      case SaltoFailureReason.keyMissing:
        return switch (_language(context)) {
          'ru' => 'Не удалось получить ключ доступа. Проверьте интернет и нажмите "Повторить".',
          'kk' => 'Қолжетімділік кілтін алу мүмкін болмады. Интернетті тексеріп, "Қайталау" басыңыз.',
          _ => 'Could not obtain your access key. Check your internet connection and tap Retry.',
        };
      case SaltoFailureReason.keyExpired:
        return switch (_language(context)) {
          'ru' => 'Срок действия ключа истёк. Нажмите "Повторить", чтобы получить новый.',
          'kk' => 'Кілттің мерзімі өтті. Жаңасын алу үшін "Қайталау" басыңыз.',
          _ => 'Your access key expired. Tap Retry to get a fresh one.',
        };
      case SaltoFailureReason.sdkTimeout:
        return switch (_language(context)) {
          'ru' => 'Турникет не ответил вовремя. Подойдите ближе и попробуйте снова.',
          'kk' => 'Турникет уақтылы жауап бермеді. Жақынырақ келіп, қайта көріңіз.',
          _ => 'The turnstile did not respond in time. Move closer and try again.',
        };
      case SaltoFailureReason.nativeFailure:
        return switch (_language(context)) {
          'ru' => 'Не удалось связаться с турникетом. Проверьте Bluetooth и попробуйте снова рядом с турникетом.',
          'kk' => 'Турникетпен байланысу мүмкін болмады. Bluetooth тексеріп, турникет жанында қайта көріңіз.',
          _ => 'Could not communicate with the turnstile. Check Bluetooth and try again close to the reader.',
        };
      case SaltoFailureReason.sdkUnavailable:
        return switch (_language(context)) {
          'ru' => 'SALTO недоступен на этом устройстве.',
          'kk' => 'SALTO бұл құрылғыда қолжетімді емес.',
          _ => 'SALTO access is not available on this device.',
        };
      case SaltoFailureReason.rejected:
      case SaltoFailureReason.none:
      case SaltoFailureReason.unknown:
        return null;
    }
  }

  Widget _buildMainButton(
    BuildContext context,
    SaltoUnlockState state,
    bool supported,
    SaltoUnlockNotifier notifier,
    AppLocalizations l10n,
    SaltoMobileStatus? status,
    bool activationRequired,
    bool statusIsLoading,
    bool statusLoadFailed,
    SaltoReadinessState readiness,
  ) {
    final isLoading =
        _isActivating ||
        state == SaltoUnlockState.scanning ||
        state == SaltoUnlockState.connecting;
    final isResult =
        state == SaltoUnlockState.granted ||
        state == SaltoUnlockState.rejected ||
        state == SaltoUnlockState.error ||
        state == SaltoUnlockState.noKey;
    // The plain unlock/retry action requires SALTO to actually be ready
    // (Bluetooth, permissions, connectivity-if-no-key, no attempt already
    // in flight) — the Open button now only enables when the flow can
    // genuinely proceed, not just when the UI *thinks* it's idle.
    // Activation and the status-load-failed fallback are separate actions
    // that don't need BLE at all, so they're never gated by BLE readiness.
    final needsReadiness = !activationRequired && !statusLoadFailed;
    final canTap = supported &&
        !isLoading &&
        !statusIsLoading &&
        (!needsReadiness || readiness.isReady);

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: canTap
            ? () async {
                SaltoAnalytics.instance.trackOpenButtonPressed();
                if (statusLoadFailed) {
                  // Status failed with no cache — still allow unlock attempt
                  // since the unlock flow only needs the digital key. This
                  // is the one path that can proceed despite bad Bluetooth/
                  // internet readiness (canTap doesn't require
                  // readiness.isReady here) — worth its own signal.
                  if (readiness.issue == SaltoReadinessIssue.bluetoothOff) {
                    SaltoAnalytics.instance.trackUnlockWhileBluetoothDisabled();
                  } else if (readiness.issue == SaltoReadinessIssue.internetUnavailable) {
                    SaltoAnalytics.instance.trackUnlockWhileOffline();
                  }
                  try {
                    await notifier.unlock();
                  } catch (e) {
                    if (!context.mounted) return;
                    AppToast.showError(context, _userFacingErrorMessage(e));
                  }
                  return;
                }
                if (activationRequired) {
                  await _activateFromAccess(context, notifier);
                  return;
                }
                if (isResult) {
                  SaltoAnalytics.instance.trackUserRetriedUnlock();
                  // Tapping a Retry-labeled button resets back to idle
                  // (button relabels to "Open") rather than immediately
                  // reattempting the unlock — the retry now takes a
                  // second, deliberate tap on "Open", by requested design:
                  // retry-arms the button instead of retry-opens-the-door
                  // on a single tap. Remember whether this arm-tap
                  // happened on a rejected key so the next tap below still
                  // runs the exact same forced-key-refresh retry the old
                  // single-tap flow used to run for that case — only the
                  // click count changes, not which call ends up firing.
                  _armedRetryNeedsKeyRefresh = state == SaltoUnlockState.rejected;
                  notifier.reset();
                  return;
                }
                if (_armedRetryNeedsKeyRefresh) {
                  _armedRetryNeedsKeyRefresh = false;
                  try {
                    await notifier.refreshAndRetry(isManual: true);
                  } catch (e) {
                    if (!context.mounted) return;
                    AppToast.showError(context, _userFacingErrorMessage(e));
                  }
                  return;
                }
                try {
                  await notifier.unlock();
                } catch (e) {
                  if (!context.mounted) return;
                  AppToast.showError(context, _userFacingErrorMessage(e));
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canTap ? AppColors.primary : AppColors.secondary,
          foregroundColor: canTap
              ? AppColors.white
              : AppColors.primary.withValues(alpha: 0.5),
          elevation: canTap ? 4 : 0,
          shadowColor: canTap ? AppColors.primary.withValues(alpha: 0.4) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                statusIsLoading
                    ? _checkingAccessText(context)
                    : statusLoadFailed
                    ? l10n.saltoAccess_open
                    : activationRequired
                    ? _activationButtonText(context, status)
                    : isResult
                    ? l10n.common_retry
                    : l10n.saltoAccess_open,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _language(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  String _checkingAccessText(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Проверяем доступ...';
      case 'kk':
        return 'Қолжетімділікті тексеріп жатырмыз...';
      default:
        return 'Checking access...';
    }
  }

  String _statusLoadErrorText(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Не удалось загрузить состояние доступа';
      case 'kk':
        return 'Қолжетімділік күйін жүктеу мүмкін болмады';
      default:
        return 'Could not load access state';
    }
  }

  bool _requiresReactivation(SaltoMobileStatus? status) {
    if (status == null) return false;
    return !status.mobileAccessEnabled ||
        status.activationRequired ||
        status.deviceBindingRequired ||
        status.shipCurrentKeyExists == false ||
        status.shipCurrentKeyStatus == 6;
  }

  String _activationRequiredText(BuildContext context, SaltoMobileStatus? status) {
    switch (_language(context)) {
      case 'ru':
        if (status?.deviceBindingRequired ?? false) {
          return 'Этот телефон нужно заново привязать к мобильному доступу';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Мобильный ключ нужно активировать заново';
        }
        return 'Сначала нужно активировать мобильный доступ';
      case 'kk':
        if (status?.deviceBindingRequired ?? false) {
          return 'Бұл телефонды мобильді қолжетімділікке қайта байланыстыру керек';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Мобильді кілтті қайта белсендіру керек';
        }
        return 'Алдымен мобильді қолжетімділікті белсендіру керек';
      default:
        if (status?.deviceBindingRequired ?? false) {
          return 'Mobile access must be re-linked on this phone';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'The mobile key must be activated again';
        }
        return 'Mobile access must be activated first';
    }
  }

  String _statusLoadHint(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Не удалось получить состояние доступа от сервера SALTO.';
      case 'kk':
        return 'SALTO серверінен қолжетімділік күйін алу мүмкін болмады.';
      default:
        return 'Could not load SALTO access state from the server.';
    }
  }

  String _statusLoadingHint(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Сейчас проверяем, доступен ли мобильный проход для этого аккаунта.';
      case 'kk':
        return 'Қазір осы аккаунт үшін мобильді қолжетімділік бар-жоғын тексеріп жатырмыз.';
      default:
        return 'We are checking whether mobile access is available for this account.';
    }
  }

  String _statusLoadingHintSecondary(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Подождите пару секунд, после этого кнопка станет доступной.';
      case 'kk':
        return 'Бірнеше секунд күтіңіз, содан кейін батырма белсенді болады.';
      default:
        return 'Please wait a moment, then the button will become available.';
    }
  }

  String _statusLoadHintSecondary(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Проверьте интернет и вход в аккаунт, затем нажмите "Повторить".';
      case 'kk':
        return 'Интернет пен аккаунтқа кіруді тексеріп, "Қайталау" түймесін басыңыз.';
      default:
        return 'Check your internet and login session, then tap Retry.';
    }
  }

  String _activationHint(BuildContext context, SaltoMobileStatus? status) {
    switch (_language(context)) {
      case 'ru':
        if (status?.deviceBindingRequired ?? false) {
          return 'Для безопасности доступ сейчас привязан к другому устройству.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Текущий мобильный ключ в SALTO еще не готов для открытия с этого телефона.';
        }
        return 'Подтвердите переключение с физической карты на проход через приложение.';
      case 'kk':
        if (status?.deviceBindingRequired ?? false) {
          return 'Қауіпсіздік үшін қолжетімділік қазір басқа құрылғыға байланыстырылған.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Ағымдағы мобильді кілт бұл телефоннан ашуға әлі дайын емес.';
        }
        return 'Физикалық картадан қолданба арқылы өтуге ауысуды растаңыз.';
      default:
        if (status?.deviceBindingRequired ?? false) {
          return 'For safety, mobile access is currently linked to another device.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'The current mobile key is not ready yet for unlock on this phone.';
        }
        return 'Confirm the switch from the physical card to access in the app.';
    }
  }

  String _activationHintSecondary(BuildContext context, SaltoMobileStatus? status) {
    switch (_language(context)) {
      case 'ru':
        if (status?.deviceBindingRequired ?? false) {
          return 'Нажмите кнопку ниже, чтобы заново выпустить ключ именно для этого телефона.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Нажмите кнопку ниже, чтобы заново выпустить и получить мобильный ключ.';
        }
        return 'После активации карта перестанет работать для турникета.';
      case 'kk':
        if (status?.deviceBindingRequired ?? false) {
          return 'Кілтті дәл осы телефон үшін қайта шығару үшін төмендегі батырманы басыңыз.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Мобильді кілтті қайта шығарып, алу үшін төмендегі батырманы басыңыз.';
        }
        return 'Белсендіргеннен кейін карта турникет үшін жұмыс істемейді.';
      default:
        if (status?.deviceBindingRequired ?? false) {
          return 'Tap below to issue the mobile key again specifically for this phone.';
        }
        if (status?.shipCurrentKeyExists == false || status?.shipCurrentKeyStatus == 6) {
          return 'Tap below to issue and receive the mobile key again.';
        }
        return 'After activation, the physical card will stop working at the turnstile.';
    }
  }

  String _activationButtonText(BuildContext context, SaltoMobileStatus? status) {
    switch (_language(context)) {
      case 'ru':
        if ((status?.deviceBindingRequired ?? false) ||
            status?.shipCurrentKeyExists == false ||
            status?.shipCurrentKeyStatus == 6) {
          return 'Перевыпустить ключ';
        }
        return 'Включить доступ в приложении';
      case 'kk':
        if ((status?.deviceBindingRequired ?? false) ||
            status?.shipCurrentKeyExists == false ||
            status?.shipCurrentKeyStatus == 6) {
          return 'Кілтті қайта шығару';
        }
        return 'Қолданбада қолжетімділікті қосу';
      default:
        if ((status?.deviceBindingRequired ?? false) ||
            status?.shipCurrentKeyExists == false ||
            status?.shipCurrentKeyStatus == 6) {
          return 'Re-issue key';
        }
        return 'Enable access in the app';
    }
  }

  String _unlockFailedText(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Не удалось открыть турникет';
      case 'kk':
        return 'Турникетті ашу мүмкін болмады';
      default:
        return 'Could not unlock the turnstile';
    }
  }

  String _unlockFailedHint(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Не удалось завершить открытие через телефон.';
      case 'kk':
        return 'Телефон арқылы ашу әрекетін аяқтау мүмкін болмады.';
      default:
        return 'The phone could not complete the unlock attempt.';
    }
  }

  String _unlockFailedHintSecondary(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Проверьте Bluetooth, разрешения Nearby devices/Location и попробуйте снова рядом с турникетом.';
      case 'kk':
        return 'Bluetooth, Nearby devices/Location рұқсаттарын тексеріп, турникет жанында қайта көріңіз.';
      default:
        return 'Check Bluetooth, Nearby devices/Location permissions, and try again close to the turnstile.';
    }
  }

  String _noKeyHintSecondary(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Нажмите "Повторить", чтобы заново запросить ключ, или обратитесь в поддержку, если проблема повторяется.';
      case 'kk':
        return 'Кілтті қайта сұрау үшін "Қайталау" түймесін басыңыз, мәселе қайталанса қолдауға жүгініңіз.';
      default:
        return 'Tap Retry to request the key again, or contact support if the issue continues.';
    }
  }

  String _activationConfirmTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Отключить карту и включить телефон?';
      case 'kk':
        return 'Картаны өшіріп, телефонды қосу керек пе?';
      default:
        return 'Disable the card and enable the phone?';
    }
  }

  String _activationConfirmDescription(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Физическая карта будет деактивирована для прохода через турникет. После этого доступ будет работать только через приложение.';
      case 'kk':
        return 'Физикалық карта турникеттен өту үшін ажыратылады. Осыдан кейін қолжетімділік тек қолданба арқылы жұмыс істейді.';
      default:
        return 'The physical card will be deactivated for turnstile access. After that, access will work only through the app.';
    }
  }

  String _activationConfirmButton(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Да, включить';
      case 'kk':
        return 'Иә, қосу';
      default:
        return 'Yes, enable';
    }
  }

  Widget _buildFaqSection(BuildContext context, ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              _faqTitle(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildFaqItem(
            context,
            theme,
            AppIcons.info,
            _faqTurnstileQuestion(context),
            _faqTurnstileAnswer(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildFaqItem(
            context,
            theme,
            AppIcons.info,
            _faqPhysicalIdQuestion(context),
            _faqPhysicalIdAnswer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    ThemeData theme,
    AppIconData icon,
    String title,
    String content,
  ) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: AppIcon(icon, size: 20, color: AppColors.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _faqTitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Часто задаваемые вопросы';
      case 'kk':
        return 'Жиі қойылатын сұрақтар';
      default:
        return 'FAQ';
    }
  }

  String _faqTurnstileQuestion(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Что делать, если турникет не открывается?';
      case 'kk':
        return 'Турникет ашылмаса не істеу керек?';
      default:
        return 'What should I do if the turnstile won\'t open?';
    }
  }

  String _faqTurnstileAnswer(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Выключите Bluetooth на 5 секунд, затем включите обратно и повторите попытку открытия турникета.';
      case 'kk':
        return 'Bluetooth-ды 5 секундқа өшіріңіз, содан кейін қайта қосып, турникетті ашуды қайталаңыз.';
      default:
        return 'Turn off Bluetooth for 5 seconds, then turn it back on and retry opening the turnstile.';
    }
  }

  String _faqPhysicalIdQuestion(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Могу ли я вернуть доступ через физическую карту?';
      case 'kk':
        return 'Физикалық карта арқылы қолжетімділікті қайтара аламын ба?';
      default:
        return 'Can I get my physical ID access back?';
    }
  }

  String _faqPhysicalIdAnswer(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Мы не можем вернуть доступ на физическую карту. Вам нужно самостоятельно обратиться в офис выдачи ID-карт.\n\nОфис выдачи ID-карт: Блок 23 (D6), 1 этаж.\nРежим работы: Пн–Пт, 8:30–17:30.\nОбед: 12:30–13:30.';
      case 'kk':
        return 'Физикалық картаға қолжетімділікті қайтару мүмкін емес. ID-карта беру кеңсесіне өзіңіз баруыңыз керек.\n\nID-карта беру кеңсесі: 23-блок (D6), 1-қабат.\nЖұмыс уақыты: Дс–Жм, 8:30–17:30.\nТүскі үзіліс: 12:30–13:30.';
      default:
        return 'We cannot restore physical ID access. You need to visit the ID issuance office in person.\n\nID Card Issuance Office: Block 23 (D6), Floor 1.\nOpen: Monday–Friday, 8:30 AM – 5:30 PM.\nClosed for lunch: 12:30 – 1:30 PM.';
    }
  }

  String _rejectedHint(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Доступ отклонён — ключ обновляется автоматически.';
      case 'kk':
        return 'Қолжетімділік қабылданбады — кілт автоматты түрде жаңартылуда.';
      default:
        return 'Access denied — refreshing key automatically.';
    }
  }

  String _rejectedHintSecondary(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Мобильный ключ обновляется каждые 7 дней. Если кнопка повторить не помогает — проверьте Bluetooth и попробуйте снова.';
      case 'kk':
        return 'Мобильді кілт 7 күн сайын жаңартылады. Қайталау батырмасы жұмыс істемесе — Bluetooth тексеріп, қайта көріңіз.';
      default:
        return 'The mobile key refreshes every 7 days. If retry doesn\'t help, check Bluetooth and try again.';
    }
  }

  String _cancelButton(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Отмена';
      case 'kk':
        return 'Бас тарту';
      default:
        return 'Cancel';
    }
  }

  String _userFacingErrorMessage(Object error) {
    if (error is SaltoRepositoryException) {
      return error.message;
    }
    return _genericErrorText(context);
  }

  String _genericErrorText(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Что-то пошло не так. Попробуйте еще раз.';
      case 'kk':
        return 'Бір нәрсе дұрыс болмады. Қайтадан көріңіз.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
