import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pin/application/pin_controller.dart';
import '../../../pin/presentation/widgets/pin_dots.dart';
import '../../../pin/presentation/widgets/pin_keyboard.dart';

/// Three-phase change PIN dialog:
/// 1. Enter old PIN
/// 2. Enter new PIN
/// 3. Confirm new PIN
class ChangePinDialog extends ConsumerStatefulWidget {
  const ChangePinDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChangePinDialog(),
    );
  }

  @override
  ConsumerState<ChangePinDialog> createState() => _ChangePinDialogState();
}

enum _ChangePinPhase { enterOld, enterNew, confirmNew }

class _ChangePinDialogState extends ConsumerState<ChangePinDialog> {
  static const _pinLength = 4;

  _ChangePinPhase _phase = _ChangePinPhase.enterOld;
  String _currentInput = '';
  String _newPin = '';
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false;

  void _onDigit(int digit) {
    if (_isProcessing || _currentInput.length >= _pinLength) return;
    setState(() {
      _currentInput += digit.toString();
      _hasError = false;
      _errorMessage = null;
    });
    if (_currentInput.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onDelete() {
    if (_isProcessing || _currentInput.isEmpty) return;
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _hasError = false;
      _errorMessage = null;
    });
  }

  Future<void> _onPinComplete() async {
    final l10n = AppLocalizations.of(context)!;

    switch (_phase) {
      case _ChangePinPhase.enterOld:
        setState(() => _isProcessing = true);
        final pinService = ref.read(pinStorageServiceProvider);
        final isValid = await pinService.verifyPin(_currentInput);
        if (!mounted) return;
        if (isValid) {
          setState(() {
            _phase = _ChangePinPhase.enterNew;
            _currentInput = '';
            _isProcessing = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = l10n.pin_incorrectError;
            _currentInput = '';
            _isProcessing = false;
          });
        }

      case _ChangePinPhase.enterNew:
        _newPin = _currentInput;
        setState(() {
          _phase = _ChangePinPhase.confirmNew;
          _currentInput = '';
        });

      case _ChangePinPhase.confirmNew:
        if (_currentInput == _newPin) {
          setState(() => _isProcessing = true);
          final pinService = ref.read(pinStorageServiceProvider);
          await pinService.createPin(_newPin);
          if (!mounted) return;
          Navigator.pop(context);
          AppToast.showSuccess(context, l10n.security_pinChanged);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = l10n.pin_mismatchError;
            _currentInput = '';
          });
        }
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_phase) {
      case _ChangePinPhase.enterOld:
        return l10n.security_enterOldPin;
      case _ChangePinPhase.enterNew:
        return l10n.security_enterNewPin;
      case _ChangePinPhase.confirmNew:
        return l10n.security_confirmNewPin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(bottom: bottomPadding + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _getTitle(l10n),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            PinDots(
              enteredLength: _currentInput.length,
              totalLength: _pinLength,
              hasError: _hasError,
            ),
            const SizedBox(height: 16),

            // Error message
            SizedBox(
              height: 20,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),

            // Keyboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: PinKeyboard(
                onDigitPressed: _onDigit,
                onDeletePressed: _onDelete,
                enabled: !_isProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
