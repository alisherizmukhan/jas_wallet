import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// Animated PIN code dot indicators.
///
/// Shows [length] dots. Filled dots represent entered digits.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.enteredLength,
    required this.totalLength,
    this.hasError = false,
    this.isSuccess = false,
  });

  /// Number of digits entered so far.
  final int enteredLength;

  /// Total number of digits expected.
  final int totalLength;

  /// Whether to show error state (red dots).
  final bool hasError;

  /// Whether to show success state (all dots green + slightly enlarged).
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalLength, (index) {
        final isFilled = isSuccess || index < enteredLength;
        final dotColor = hasError
            ? AppColors.error
            : isSuccess
            ? AppColors.success
            : isFilled
            ? AppColors.primary
            : Colors.transparent;
        final borderColor = hasError
            ? AppColors.error
            : isSuccess
            ? AppColors.success
            : isFilled
            ? AppColors.primary
            : AppColors.grey.withValues(alpha: 0.4);
        final size = isSuccess ? 18.0 : isFilled ? 16.0 : 14.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            border: Border.all(color: borderColor, width: 2),
          ),
        );
      }),
    );
  }
}
