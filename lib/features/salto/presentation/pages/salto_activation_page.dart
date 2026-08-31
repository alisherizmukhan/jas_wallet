import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../analytics/salto_analytics.dart';
import '../../data/repositories/salto_repository_impl.dart';
import '../providers/salto_activation_provider.dart';
import '../providers/salto_activation_readiness_provider.dart';
import '../providers/salto_provider.dart';
import '../widgets/salto_activation_prerequisites.dart';

class SaltoActivationPage extends ConsumerStatefulWidget {
  const SaltoActivationPage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  ConsumerState<SaltoActivationPage> createState() => _SaltoActivationPageState();
}

class _SaltoActivationPageState extends ConsumerState<SaltoActivationPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;

  /// Whether the user was sent to system Settings from a prerequisite
  /// dialog on this visit — used only to log a precise "returned from
  /// settings" event on the next resume, distinct from an ordinary
  /// foreground-poll refresh.
  bool _awaitingSettingsReturn = false;

  /// Ambient readiness is re-checked this often while the app is in the
  /// foreground — cheap local/native reads only, bounded to foreground so
  /// it costs nothing while backgrounded. This is what lets the page
  /// notice Bluetooth/internet becoming available without the user
  /// needing to reopen it or press a manual refresh.
  static const _readinessPollInterval = Duration(seconds: 3);
  Timer? _readinessPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startReadinessPolling();
  }

  @override
  void dispose() {
    _stopReadinessPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// On resume, automatically re-check Bluetooth/internet/readiness — the
  /// user should never need to reopen this page or press a manual refresh
  /// after fixing something in Settings. On backgrounding, stop polling;
  /// it only needs to run while the page is actually visible.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SaltoAnalytics.instance.updateAppLifecycleState(state.name);
    if (state == AppLifecycleState.resumed) {
      final returnedFromSettings = _awaitingSettingsReturn;
      if (_awaitingSettingsReturn) {
        _awaitingSettingsReturn = false;
        unawaited(ref.read(saltoActivationProvider.notifier).logSettingsReturned());
        SaltoAnalytics.instance.trackUserReturnedFromSettings();
        switch (SaltoActivationPrerequisites.lastSettingsTypeOpened) {
          case 'bluetooth':
            SaltoAnalytics.instance.trackBluetoothSettingsReturned(flow: 'activation');
          case 'network':
            SaltoAnalytics.instance.trackNetworkSettingsReturned();
        }
      }
      ref.read(saltoActivationReadinessProvider.notifier).refresh();
      _startReadinessPolling();
      if (returnedFromSettings) unawaited(_continueAfterSettings());
    } else {
      _stopReadinessPolling();
    }
  }

  /// The auto-recovery a prerequisite promises when it sends the user to
  /// Settings: pick the flow back up on return instead of leaving them
  /// looking at an unchanged screen, wondering whether their tap registered.
  ///
  /// Only continues once readiness actually clears — if they came back
  /// without turning Bluetooth on, re-opening the same dialog they just
  /// dismissed would be a loop, so the ambient status line explains the
  /// blocker instead. The destructive confirmation still gates activation, so
  /// this can never enable mobile access without an explicit tap.
  Future<void> _continueAfterSettings() async {
    await ref.read(saltoActivationReadinessProvider.notifier).refresh();
    if (!mounted || _isLoading) return;
    if (!ref.read(saltoActivationReadinessProvider).isReady) return;
    await _activateMobileAccess();
  }

  void _startReadinessPolling() {
    _readinessPollTimer?.cancel();
    _readinessPollTimer = Timer.periodic(_readinessPollInterval, (_) {
      if (mounted) ref.read(saltoActivationReadinessProvider.notifier).refresh();
    });
  }

  void _stopReadinessPolling() {
    _readinessPollTimer?.cancel();
    _readinessPollTimer = null;
  }

  Future<void> _continueToAuthFlow() async {
    final storage = ref.read(authStorageServiceProvider);
    final accessToken = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();

    await ref.read(authProvider.notifier).login(
      userId: widget.userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> _skipActivation() async {
    setState(() => _isLoading = true);
    try {
      await _continueToAuthFlow();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _activateMobileAccess() async {
    // Defense-in-depth: the confirmation dialog below is already
    // non-dismissible and modal (its barrier blocks the button underneath),
    // but gating here too means "one tap = one activation attempt" holds
    // even if that ever changes. Guarantees the button can't be re-entered
    // while a previous attempt (dialog + POST + follow-up) is still running.
    if (_isLoading) {
      SaltoAnalytics.instance.trackRapidMultipleTaps(tapContext: 'activation_button');
      return;
    }

    setState(() => _isLoading = true);
    SaltoAnalytics.instance.trackActivationButtonPressed();
    try {
      // Prerequisites run *before* the confirmation, not after. Asking the
      // user to commit to disabling their physical card and only then
      // bouncing them to Bluetooth settings threw that commitment away — they
      // came back to an unchanged screen and had to confirm the same scary
      // dialog a second time, which reads as "my tap did nothing".
      final prereq = await SaltoActivationPrerequisites.ensureReady(context, ref);
      if (prereq == SaltoPrerequisiteResult.wentToSettings) {
        _awaitingSettingsReturn = true;
        return; // auto-recovery on resume — see didChangeAppLifecycleState
      }
      if (prereq == SaltoPrerequisiteResult.cancelled) return;
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      SaltoAnalytics.instance.trackActivationConfirmDialogOpened();
      final confirmed = await AppPremiumDialog.show(
        context: context,
        icon: AppIcons.phone,
        iconColor: const Color(0xFF007AFF),
        title: l10n.salto_switchAccessConfirmTitle,
        description: l10n.salto_switchAccessConfirmDescription,
        confirmText: l10n.salto_yesSwitch,
        cancelText: l10n.common_cancel,
        // This confirmation disables physical card access — an accidental
        // swipe-down or a tap on the dimmed background must never be
        // silently treated the same as tapping Cancel. The user must land
        // on an explicit button.
        isDismissible: false,
        enableDrag: false,
      );
      if (!confirmed) {
        SaltoAnalytics.instance.trackActivationCancelled();
        SaltoAnalytics.instance.trackUserCancelledActivation();
        return;
      }
      if (!mounted) return;
      SaltoAnalytics.instance.trackActivationConfirmed();

      final result = await ref.read(saltoActivationProvider.notifier).activate();
      if (result == null) {
        // Activation was correctly refused before the POST was ever sent
        // (offline, or another attempt already in flight) — never silent.
        if (!mounted) return;
        final reason =
            ref.read(saltoActivationProvider.notifier).lastFailureReason;
        AppToast.showError(context, _activationGateMessage(reason));
        return;
      }

      if (!mounted) return;
      if (result.message != null && result.message!.isNotEmpty) {
        AppToast.showInfo(context, result.message!);
      }
      await _continueToAuthFlow();
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, _userFacingErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Message for activation being refused *before* the POST was attempted
  /// — distinct from [_userFacingErrorMessage], which covers a POST that
  /// was actually sent and rejected/failed.
  String _activationGateMessage(SaltoActivationFailureReason reason) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (reason) {
      case SaltoActivationFailureReason.internetUnavailable:
        switch (lang) {
          case 'ru':
            return 'Нет подключения к интернету. Подключитесь к интернету и попробуйте снова.';
          case 'kk':
            return 'Интернет байланысы жоқ. Интернетке қосылып, қайта көріңіз.';
          default:
            return 'No internet connection. Please connect to the internet and try again.';
        }
      case SaltoActivationFailureReason.alreadyActivating:
        switch (lang) {
          case 'ru':
            return 'Активация уже выполняется. Пожалуйста, подождите.';
          case 'kk':
            return 'Белсендіру әлдеқашан жүріп жатыр. Күте тұрыңыз.';
          default:
            return 'Activation is already in progress. Please wait.';
        }
      // Deliberately does not say "try again": the request may still be
      // completing on the server, and a second activation cancels the key the
      // first one is issuing.
      case SaltoActivationFailureReason.timedOutStillRunning:
        switch (lang) {
          case 'ru':
            return 'Активация занимает больше времени, чем обычно, и еще может завершиться. Подождите минуту и обновите экран — не нажимайте кнопку повторно.';
          case 'kk':
            return 'Белсендіру әдеттегіден ұзағырақ жүріп жатыр және әлі аяқталуы мүмкін. Бір минут күтіп, экранды жаңартыңыз — түймені қайта баспаңыз.';
          default:
            return 'This is taking longer than usual and may still be completing. Please wait a minute and refresh — do not tap again.';
        }
      case SaltoActivationFailureReason.backendRejected:
      case SaltoActivationFailureReason.unknown:
      case SaltoActivationFailureReason.none:
        switch (lang) {
          case 'ru':
            return 'Не удалось включить мобильный доступ. Попробуйте еще раз.';
          case 'kk':
            return 'Мобильді қолжетімділікті қосу мүмкін болмады. Қайта көріңіз.';
          default:
            return 'Could not enable mobile access. Please try again.';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final statusAsync = ref.watch(saltoStatusProvider);
    final alreadyEnabled = statusAsync.valueOrNull?.mobileAccessEnabled ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: false,
        showDivider: false,
        title: l10n.salto_mobileAccess,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alreadyEnabled
                          ? l10n.salto_mobileAccessAlreadyEnabled
                          : l10n.salto_enableAccessInApp,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      alreadyEnabled
                          ? l10n.salto_mobileKeyAlreadyIssued
                          : l10n.salto_switchToMobileKeyDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLight ? AppColors.textSecondary : AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.salto_physicalCardWarning,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!alreadyEnabled) ...[
                _buildReadinessStatus(context, theme),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (alreadyEnabled ? _continueToAuthFlow : _activateMobileAccess),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          alreadyEnabled ? l10n.common_continue : l10n.salto_activateInApp,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _skipActivation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.salto_skipForNow,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Ambient, Apple-Wallet/Revolut-style status line shown just above the
  /// action button — the user sees *why* activation isn't fully ready
  /// (or that it is) before ever tapping, rather than only discovering a
  /// blocker after pressing the button. Never disables the button itself
  /// (per design — see SaltoActivationPrerequisites); tapping while an
  /// issue is present surfaces the same information via a dialog.
  Widget _buildReadinessStatus(BuildContext context, ThemeData theme) {
    final readiness = ref.watch(saltoActivationReadinessProvider);
    final (icon, color) = _readinessVisual(readiness.issue);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _readinessText(readiness.issue),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  (AppIconData, Color) _readinessVisual(SaltoActivationReadinessIssue issue) {
    switch (issue) {
      case SaltoActivationReadinessIssue.none:
        return (AppIcons.check, AppColors.green);
      case SaltoActivationReadinessIssue.checkingStatus:
      case SaltoActivationReadinessIssue.preparingDevice:
      case SaltoActivationReadinessIssue.alreadyActivating:
        return (AppIcons.refresh, AppColors.grey);
      case SaltoActivationReadinessIssue.internetUnavailable:
        return (AppIcons.wifiOff, AppColors.error);
      case SaltoActivationReadinessIssue.bluetoothOff:
      case SaltoActivationReadinessIssue.bluetoothNotReady:
      case SaltoActivationReadinessIssue.bluetoothUnauthorized:
      case SaltoActivationReadinessIssue.bluetoothUnsupported:
        return (AppIcons.bluetoothOff, const Color(0xFFFF9500));
      case SaltoActivationReadinessIssue.notAuthenticated:
        return (AppIcons.warning, AppColors.error);
    }
  }

  String _readinessText(SaltoActivationReadinessIssue issue) {
    switch (issue) {
      case SaltoActivationReadinessIssue.none:
        return switch (_language(context)) {
          'ru' => 'Готово к активации',
          'kk' => 'Белсендіруге дайын',
          _ => 'Ready to activate',
        };
      case SaltoActivationReadinessIssue.checkingStatus:
        return switch (_language(context)) {
          'ru' => 'Проверяем мобильный доступ...',
          'kk' => 'Мобильді қолжетімділікті тексеріп жатырмыз...',
          _ => 'Checking mobile access...',
        };
      case SaltoActivationReadinessIssue.preparingDevice:
        return switch (_language(context)) {
          'ru' => 'Подготавливаем ваше устройство...',
          'kk' => 'Құрылғыңызды дайындап жатырмыз...',
          _ => 'Preparing your device...',
        };
      // Names the duration on purpose. Activation runs a long chain of
      // sequential SALTO operations, and a spinner with no expectation set is
      // what makes a student decide the button is stuck and tap it again.
      case SaltoActivationReadinessIssue.alreadyActivating:
        return switch (_language(context)) {
          'ru' => 'Регистрация устройства — это может занять до минуты',
          'kk' => 'Құрылғыны тіркеу — бұл бір минутқа дейін созылуы мүмкін',
          _ => 'Registering your device — this can take up to a minute',
        };
      case SaltoActivationReadinessIssue.internetUnavailable:
        return switch (_language(context)) {
          'ru' => 'Нет подключения к интернету',
          'kk' => 'Интернет байланысы жоқ',
          _ => 'No Internet Connection',
        };
      case SaltoActivationReadinessIssue.bluetoothOff:
        return switch (_language(context)) {
          'ru' => 'Bluetooth выключен',
          'kk' => 'Bluetooth өшірулі',
          _ => 'Bluetooth is turned off',
        };
      case SaltoActivationReadinessIssue.bluetoothNotReady:
        return switch (_language(context)) {
          'ru' => 'Bluetooth еще включается...',
          'kk' => 'Bluetooth әлі қосылып жатыр...',
          _ => 'Bluetooth is starting up...',
        };
      case SaltoActivationReadinessIssue.bluetoothUnauthorized:
        return switch (_language(context)) {
          'ru' => 'Нет разрешения на Bluetooth',
          'kk' => 'Bluetooth рұқсаты жоқ',
          _ => 'Bluetooth permission denied',
        };
      case SaltoActivationReadinessIssue.bluetoothUnsupported:
        return switch (_language(context)) {
          'ru' => 'Устройство не поддерживает Bluetooth',
          'kk' => 'Құрылғы Bluetooth-ты қолдамайды',
          _ => 'This device does not support Bluetooth',
        };
      case SaltoActivationReadinessIssue.notAuthenticated:
        return switch (_language(context)) {
          'ru' => 'Сессия истекла — войдите снова',
          'kk' => 'Сеанс аяқталды — қайта кіріңіз',
          _ => 'Session expired — please sign in again',
        };
    }
  }

  String _language(BuildContext context) => Localizations.localeOf(context).languageCode;

  String _userFacingErrorMessage(Object error) {
    if (error is SaltoRepositoryException) {
      return error.message;
    }

    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Не удалось включить мобильный доступ. Попробуйте еще раз.';
      case 'kk':
        return 'Мобильді қолжетімділікті қосу мүмкін болмады. Қайта көріңіз.';
      default:
        return 'Could not enable mobile access. Please try again.';
    }
  }
}
