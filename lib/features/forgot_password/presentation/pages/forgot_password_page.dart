import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';

/// Forgot password page - email-only recovery with @nu.edu.kz validation.
/// Design: Back button, Title, Description, Email input, Send Code button, Social contacts.
///
/// Flow: Enter email → OTP verification (6 digits) → Reset Password page.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@nu\.edu\.kz$');
    return regex.hasMatch(email);
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = null;
      } else if (!value.contains('@')) {
        _emailError = 'Invalid email format';
      } else if (!_isEmailValid(value)) {
        _emailError = 'Only @nu.edu.kz emails are allowed';
      } else {
        _emailError = null;
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_isEmailValid(_emailController.text)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      context.push(
        AppRoutes.verification,
        extra: {
          'destination': email,
          'isPhone': false,
          'flow': 'reset',
        },
      );
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isValid = _isEmailValid(_emailController.text);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppAppBar(showBackButton: true, showDivider: false),
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
                l10n.forgotPassword_title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLight ? AppColors.textColor : AppColors.textColorDark,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                l10n.forgotPassword_enterEmail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
              ),

              const SizedBox(height: 32),

              // Email input
              Container(
                decoration: BoxDecoration(
                  color: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: _emailError != null
                      ? Border.all(color: AppColors.red, width: 1)
                      : null,
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: _validateEmail,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLight ? AppColors.textColor : AppColors.textColorDark,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.auth_emailExample,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppIcon(
                        AppIcons.email,
                        color: AppColors.grey,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              // Email validation error
              if (_emailError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _emailError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.red,
                  ),
                ),
              ],

              const Spacer(),

              // Send Code button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isValid ? _sendCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
                        ? AppColors.primary
                        : AppColors.secondary,
                    foregroundColor: isValid
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
                          l10n.auth_sendCode,
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


