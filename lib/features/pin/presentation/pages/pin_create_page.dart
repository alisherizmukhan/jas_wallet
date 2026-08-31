import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../application/pin_controller.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keyboard.dart';

/// PIN code creation page.
///
/// Shown after first successful login / registration.
/// User enters a 4-digit PIN, then confirms it.
class PinCreatePage extends ConsumerStatefulWidget {
  const PinCreatePage({super.key});

  @override
  ConsumerState<PinCreatePage> createState() => _PinCreatePageState();
}

class _PinCreatePageState extends ConsumerState<PinCreatePage>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  static const int _pinLength = 4;

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(int digit) {
    if (_enteredPin.length >= _pinLength) return;

    setState(() {
      _enteredPin += digit.toString();
      _hasError = false;
    });

    if (_enteredPin.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _onPinComplete() async {
    final controller = ref.read(pinCreateControllerProvider.notifier);
    final state = ref.read(pinCreateControllerProvider);

    if (state.phase == PinEntryPhase.create) {
      controller.setPin(_enteredPin);
      setState(() {
        _enteredPin = '';
      });
    } else {
      final success = await controller.confirmPin(_enteredPin);
      if (!success && mounted) {
        setState(() {
          _enteredPin = '';
          _hasError = true;
        });
        _shakeController.forward().then((_) => _shakeController.reset());
      } else if (success && mounted) {
        if (mounted) {
          AnalyticsService.instance.trackPinCreated();
          // After PIN is created, transition to biometric setup page
          // (User can enable or skip biometrics there)
          await ref
              .read(authProvider.notifier)
              .completePinSetup(showBiometricSetup: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pinState = ref.watch(pinCreateControllerProvider);
    final isConfirmPhase = pinState.phase == PinEntryPhase.confirm;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Spacer(flex: 2),

              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppIcon(
                  AppIcons.lock,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isConfirmPhase ? l10n.pin_confirmTitle : l10n.pin_createTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.textColor : AppColors.textColorDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                isConfirmPhase
                    ? l10n.pin_confirmSubtitle
                    : l10n.pin_createSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN dots with shake animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? _shakeAnimation.value *
                                ((_shakeController.value * 4).round().isEven
                                    ? 1
                                    : -1)
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: PinDots(
                  enteredLength: _enteredPin.length,
                  totalLength: _pinLength,
                  hasError: _hasError,
                ),
              ),

              // Error message
              if (pinState.error == 'pin_mismatch') ...[
                const SizedBox(height: 16),
                Text(
                  l10n.pin_mismatchError,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],

              const Spacer(flex: 1),

              // Keyboard
              PinKeyboard(
                onDigitPressed: _onDigitPressed,
                onDeletePressed: _onDeletePressed,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
