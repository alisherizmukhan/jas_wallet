import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';

/// Reset password page - set new password after verification.
/// Requires [email] and [code] from verification step.
/// Design: Back button + logo, title, new password, confirm password, button.
/// Shows success screen after reset.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  bool get _isValid {
    return widget.email.isNotEmpty &&
        widget.code.length == 6 &&
        isPasswordValid(_passwordController.text) &&
        _passwordsMatch;
  }

  Future<void> _resetPassword() async {
    if (!_isValid) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(
        context,
        e.toString().replaceFirst('AuthException: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _SuccessScreen();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppAppBar(showBackButton: true),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const SizedBox(height: 24),

              // Title
              Text(
                l10n.forgotPassword_reset,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.textColor : AppColors.textColorDark,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                l10n.forgotPassword_resetDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 32),

              // New password field
              _InputField(
                controller: _passwordController,
                hintText: l10n.forgotPassword_newPassword,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? l10n.common_showPassword
                      : l10n.common_hidePassword,
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: AppIcon(
                    _obscurePassword
                        ? AppIcons.visibilityOff
                        : AppIcons.visibility,
                    color: AppColors.grey,
                  ),
                ),
              ),

              // Password rule hint — turns red when the password is non-empty
              // and does not meet the policy.
              const SizedBox(height: 8),
              Text(
                l10n.auth_passwordRule,
                style: TextStyle(
                  fontSize: 12,
                  color: _passwordController.text.isNotEmpty &&
                          !isPasswordValid(_passwordController.text)
                      ? AppColors.error
                      : AppColors.grey,
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password field
              _InputField(
                controller: _confirmPasswordController,
                hintText: l10n.forgotPassword_confirmPassword,
                obscureText: _obscureConfirmPassword,
                onChanged: (_) => setState(() {}),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? l10n.common_showPassword
                      : l10n.common_hidePassword,
                  onPressed: () {
                    setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  icon: AppIcon(
                    _obscureConfirmPassword
                        ? AppIcons.visibilityOff
                        : AppIcons.visibility,
                    color: AppColors.grey,
                  ),
                ),
              ),

              if (_confirmPasswordController.text.isNotEmpty &&
                  !_passwordsMatch) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.auth_passwordsDoNotMatch,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],

              const Spacer(),

              // Reset button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isValid ? _resetPassword : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isValid ? AppColors.primary : AppColors.secondary,
                    foregroundColor: _isValid
                        ? AppColors.white
                        : AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
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
                          l10n.forgotPassword_reset,
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
          ),
        ),
      ),
    );
  }
}

/// Success screen after password reset.
class _SuccessScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Spacer(),

              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.star,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Success title
              Text(
                l10n.forgotPassword_success,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.textColor : AppColors.textColorDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Success description
              Text(
                l10n.forgotPassword_successDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Go to login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.auth_login,
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
}

/// Custom input field with consistent styling.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: isLight ? AppColors.textColor : AppColors.textColorDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            color: AppColors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
