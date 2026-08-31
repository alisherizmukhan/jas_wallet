import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/biometric/biometric_providers.dart';
import '../../../salto/presentation/providers/salto_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../application/pin_controller.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keyboard.dart';

/// PIN verification page.
///
/// Shown as the foreground layer of [PinUnlockOverlay] when the app requires
/// local authentication. The overlay owns the slide-away animation; this page
/// only owns PIN entry UI, the success state (green dots + haptic), and the
/// auth state transition.
///
/// Unlock sequence:
///  1. User enters 4th digit → hash check (fast, in-memory after warmUp)
///  2. On success: haptic + dots turn green (80ms hold for user to register)
///  3. completeLocalAuth() fires → AuthStatus.authenticated
///  4. PinUnlockOverlay detects state change → slides panel downward
class PinVerifyPage extends ConsumerStatefulWidget {
  const PinVerifyPage({super.key});

  @override
  ConsumerState<PinVerifyPage> createState() => _PinVerifyPageState();
}

class _PinVerifyPageState extends ConsumerState<PinVerifyPage>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  bool _isUnlocking = false;
  bool _isSuccess = false;
  static const int _pinLength = 4;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricTriggered = false;

  /// True when biometric is enabled in-app but NOT available on the device.
  bool _biometricDisabledAtOs = false;

  Timer? _lockTimer;
  int _lockSeconds = 0;

  // Shake controller — wrong PIN feedback
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Get biometric enabled state from cached auth state (instant, no I/O)
    final authState = ref.read(authProvider);
    _biometricEnabled = authState.biometricEnabled;

    // Warm up PIN material AND session credentials in parallel for instant unlock.
    final pinService = ref.read(pinStorageServiceProvider);
    final pinController = ref.read(pinVerifyControllerProvider.notifier);
    unawaited(Future.wait([
      pinService.warmUp(),
      pinController.warmSessionData(),
    ]));

    // Silently refresh SALTO key while the user enters their PIN so the
    // Access page opens with a fresh key ready in memory.
    ref.read(saltoKeyManagerProvider).prewarm();

    // Start biometric check immediately (don't wait for frame)
    _initBiometric();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    final available = await biometricService.isBiometricAvailable();
    final enabled = _biometricEnabled;

    final invalidatedByOs = enabled && !available;
    if (invalidatedByOs) {
      await biometricService.disableBiometric();
      await ref.read(authStorageServiceProvider).setBiometricEnabled(false);
      await ref.read(authProvider.notifier).syncBiometricPreference();
    }

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled && available;
      _biometricDisabledAtOs = invalidatedByOs;
    });

    if (available && enabled && !invalidatedByOs && !_biometricTriggered) {
      _biometricTriggered = true;
      _authenticateWithBiometric();
    }
  }

  // ── Success feedback ───────────────────────────────────────────────────────

  /// Shows haptic + green dots, then triggers the auth state change.
  /// PinUnlockOverlay responds to the auth change and plays the slide animation.
  Future<void> _animateUnlock() async {
    HapticFeedback.lightImpact();
    if (mounted) setState(() => _isSuccess = true);
    // Brief hold so the user registers the green success state.
    await Future.delayed(const Duration(milliseconds: 80));
  }

  // ── Biometric ──────────────────────────────────────────────────────────────

  Future<void> _authenticateWithBiometric() async {
    if (_isUnlocking) return;

    final biometricService = ref.read(biometricAuthServiceProvider);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final success = await biometricService.authenticate(
      reason: l10n.pin_biometricReason,
    );

    if (!success || !mounted) return;

    setState(() {
      _hasError = false;
      _isUnlocking = true;
    });

    AnalyticsService.instance.trackBiometricAuthSuccess();
    final authState = ref.read(authProvider);
    if (authState.userId != null) {
      AnalyticsService.instance.identify(authState.userId!);
      AnalyticsService.instance.trackSessionRestored();
    }

    await _animateUnlock();
    if (!mounted) return;

    final unlocked = await ref
        .read(pinVerifyControllerProvider.notifier)
        .completeLocalAuth();

    if (!mounted) return;
    if (unlocked) return;

    // Rare: session invalidated between biometric check and auth completion.
    final verifyState = ref.read(pinVerifyControllerProvider);
    if (verifyState.forceReAuth) {
      await ref.read(pinVerifyControllerProvider.notifier).executeForceReAuth();
      return;
    }

    setState(() {
      _hasError = true;
      _isUnlocking = false;
      _isSuccess = false;
    });
    _triggerShake();
  }

  /// Plays the wrong-PIN shake, unless the system "reduce motion" setting
  /// is on — the error state (red dots, error text) is still shown either
  /// way, only the shake motion itself is skipped.
  void _triggerShake() {
    if (MediaQuery.of(context).disableAnimations) return;
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  // ── PIN entry ──────────────────────────────────────────────────────────────

  void _onDigitPressed(int digit) {
    if (_enteredPin.length >= _pinLength || _lockSeconds > 0 || _isUnlocking) {
      return;
    }

    setState(() {
      _enteredPin += digit.toString();
      _hasError = false;
    });

    if (_enteredPin.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty || _isUnlocking) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _onPinComplete() async {
    if (_isUnlocking) return;

    setState(() {
      _hasError = false;
      _isUnlocking = true;
    });

    final controller = ref.read(pinVerifyControllerProvider.notifier);

    // Fast hash comparison — in-memory after warmUp, typically < 5ms.
    final isValid = await controller.checkPinHash(_enteredPin);

    if (!mounted) return;

    if (isValid) {
      AnalyticsService.instance.trackPinVerified();
      final authState = ref.read(authProvider);
      if (authState.userId != null) {
        AnalyticsService.instance.identify(authState.userId!);
        AnalyticsService.instance.trackSessionRestored();
      }
      await _animateUnlock();
      if (!mounted) return;

      // Auth → authenticated; PinUnlockOverlay responds and slides panel away.
      final success = await controller.completeLocalAuth();

      if (!mounted) return;

      if (!success) {
        final verifyState = ref.read(pinVerifyControllerProvider);
        if (verifyState.forceReAuth) {
          await controller.executeForceReAuth();
        }
      }
      return;
    }

    // PIN incorrect — record failure (increments counter, checks lock).
    await controller.recordPinFailure();

    if (!mounted) return;

    final verifyState = ref.read(pinVerifyControllerProvider);
    AnalyticsService.instance.trackPinFailed(
      attemptsRemaining: AuthNotifier.maxPinAttempts - (verifyState.failedAttempts),
    );

    if (verifyState.forceReAuth) {
      await controller.executeForceReAuth();
      return;
    }

    setState(() {
      _enteredPin = '';
      _hasError = true;
      _isUnlocking = false;
    });
    _triggerShake();

    if (verifyState.isLocked) {
      _startLockTimer(verifyState.lockRemainingSeconds);
    }
  }

  void _startLockTimer(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockSeconds = seconds);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockSeconds--;
        if (_lockSeconds <= 0) {
          timer.cancel();
          _lockSeconds = 0;
          ref.read(pinVerifyControllerProvider.notifier).checkLockStatus();
        }
      });
    });
  }

  Future<void> _logout() async {
    final biometricService = ref.read(biometricAuthServiceProvider);
    await ref
        .read(authProvider.notifier)
        .logout(biometricService: biometricService);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final verifyState = ref.watch(pinVerifyControllerProvider);
    final isLocked = _lockSeconds > 0;
    final errorText = _errorText(context, verifyState, l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use compact layout on short screens (e.g. iPhone SE, small Android)
            // to prevent overflow — reduces logo, gaps, and key sizes.
            final compact = constraints.maxHeight < 700;
            final logoSize = compact ? 48.0 : 64.0;
            final logoGap = compact ? 12.0 : 24.0;
            final dotsGap = compact ? 20.0 : 40.0;
            final bottomGap = compact ? 8.0 : 16.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  AppIcon(AppIcons.logo, size: logoSize),
                  SizedBox(height: logoGap),

                  // Title
                  Text(
                    l10n.pin_enterTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isLight
                          ? AppColors.black
                          : AppColors.textPrimaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle / Lock message / Biometric-disabled notice
                  if (isLocked)
                    Text(
                      l10n.pin_lockedMessage(_lockSeconds),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    Text(
                      l10n.pin_enterSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? AppColors.textSecondaryOnLight
                            : AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_biometricDisabledAtOs) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.pin_biometricUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                  SizedBox(height: dotsGap),

                  // PIN dots with shake on error and green on success.
                  // Wrapped in SentryMask so a Sentry crash screenshot never
                  // shows PIN entry progress/state, even though the dots
                  // themselves never render the actual digits.
                  // ignore: experimental_member_use
                  SentryMask(
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                            _shakeController.isAnimating
                                ? _shakeAnimation.value *
                                      ((_shakeController.value * 4)
                                              .round()
                                              .isEven
                                          ? 1
                                          : -1)
                                : 0,
                            0,
                          ),
                          child: child,
                        ),
                        child: PinDots(
                          enteredLength: _enteredPin.length,
                          totalLength: _pinLength,
                          hasError: _hasError,
                          isSuccess: _isSuccess,
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (errorText != null && !isLocked && !_isUnlocking) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  const Spacer(flex: 1),

                  // Keyboard — compact on short screens to avoid overflow.
                  // Masked in Sentry crash screenshots for the same reason
                  // as PinDots above.
                  // ignore: experimental_member_use
                  SentryMask(
                    PinKeyboard(
                      onDigitPressed: _onDigitPressed,
                      onDeletePressed: _onDeletePressed,
                      showBiometric: _biometricAvailable && _biometricEnabled,
                      onBiometricPressed: _authenticateWithBiometric,
                      enabled: !isLocked && !_isUnlocking,
                      compact: compact,
                    ),
                  ),

                  SizedBox(height: bottomGap),

                  // Switch account (logout) button
                  TextButton(
                    onPressed: _isUnlocking ? null : _logout,
                    child: Text(
                      l10n.pin_switchAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLight
                            ? AppColors.textSecondaryOnLight
                            : AppColors.grey,
                      ),
                    ),
                  ),

                  SizedBox(height: bottomGap),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String? _errorText(
    BuildContext context,
    PinVerifyState verifyState,
    AppLocalizations l10n,
  ) {
    switch (verifyState.error) {
      case 'pin_incorrect':
        return l10n.pin_incorrectError;
      case 'session_refresh_failed':
        return l10n.pin_sessionRefreshFailed;
      case 'session_expired':
      case 'pin_force_reauth':
        return l10n.pin_sessionExpired;
      default:
        return null;
    }
  }
}
