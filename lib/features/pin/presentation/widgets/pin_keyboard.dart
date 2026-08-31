import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Numeric keyboard for PIN entry.
///
/// Displays 0-9 digits, a delete button, and an optional biometric button.
/// On compact (short) screens the key size and row gaps are reduced so the
/// keyboard fits without overflow.
class PinKeyboard extends StatelessWidget {
  const PinKeyboard({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onBiometricPressed,
    this.showBiometric = false,
    this.enabled = true,
    this.compact = false,
  });

  /// Called when a digit key (0–9) is pressed.
  final ValueChanged<int> onDigitPressed;

  /// Called when the delete/backspace key is pressed.
  final VoidCallback onDeletePressed;

  /// Called when the biometric key is pressed.
  final VoidCallback? onBiometricPressed;

  /// Whether to show the biometric button in the bottom-left.
  final bool showBiometric;

  /// Whether the keyboard is enabled (disabled during lock-out).
  final bool enabled;

  /// Whether to use smaller keys and tighter gaps for short screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final keySize = compact ? 60.0 : 72.0;
    final gap = compact ? 10.0 : 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow([1, 2, 3], keySize: keySize),
        SizedBox(height: gap),
        _buildRow([4, 5, 6], keySize: keySize),
        SizedBox(height: gap),
        _buildRow([7, 8, 9], keySize: keySize),
        SizedBox(height: gap),
        _buildBottomRow(context, keySize: keySize),
      ],
    );
  }

  Widget _buildRow(List<int> digits, {required double keySize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (digit) => _DigitKey(
              key: Key('pinKey_$digit'),
              digit: digit,
              size: keySize,
              onPressed: enabled ? () => onDigitPressed(digit) : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context, {required double keySize}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric or empty space
        if (showBiometric)
          _BiometricKey(
            key: const Key('pinKeyBiometric'),
            size: keySize,
            semanticLabel: l10n.common_useBiometric,
            onPressed: enabled ? onBiometricPressed : null,
          )
        else
          SizedBox(width: keySize, height: keySize),

        // Zero digit
        _DigitKey(
          key: const Key('pinKey_0'),
          digit: 0,
          size: keySize,
          onPressed: enabled ? () => onDigitPressed(0) : null,
        ),

        // Delete
        _ActionKey(
          key: const Key('pinKeyDelete'),
          size: keySize,
          icon: AppIcons.delete,
          semanticLabel: l10n.common_delete,
          onPressed: enabled ? onDeletePressed : null,
        ),
      ],
    );
  }
}

/// A single digit key on the PIN keyboard.
class _DigitKey extends StatelessWidget {
  const _DigitKey({
    super.key,
    required this.digit,
    required this.size,
    this.onPressed,
  });

  final int digit;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fontSize = size >= 70 ? 28.0 : 22.0;

    return AppPressable(
      enabled: onPressed != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
            ),
            child: Text(
              '$digit',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: isLight ? AppColors.textColor : AppColors.textColorDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An action key (biometric / delete) on the PIN keyboard.
class _ActionKey extends StatelessWidget {
  const _ActionKey({
    super.key,
    required this.icon,
    required this.size,
    required this.semanticLabel,
    this.onPressed,
  });

  final AppIconData icon;
  final double size;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconSize = size >= 70 ? 28.0 : 22.0;

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: AppPressable(
        enabled: onPressed != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: AppIcon(
                icon,
                size: iconSize,
                color: onPressed != null ? AppColors.primary : AppColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Face ID / biometric key using the SVG icon from the design system.
class _BiometricKey extends StatelessWidget {
  const _BiometricKey({
    super.key,
    required this.size,
    required this.semanticLabel,
    this.onPressed,
  });

  final double size;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconSize = size >= 70 ? 28.0 : 22.0;

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: AppPressable(
        enabled: onPressed != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: AppIcon(
                  AppIcons.faceId,
                  size: iconSize,
                  colorFilter: ColorFilter.mode(
                    onPressed != null ? AppColors.primary : AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
