import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';

/// Change password dialog matching the design.
/// Shows old password, new password, confirm password fields and performs the
/// real password change via the backend.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isFormValid {
    return _oldPasswordController.text.isNotEmpty &&
        isPasswordValid(_newPasswordController.text) &&
        _confirmPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.surfaceDark,
            borderRadius: AppSpacing.borderRadiusTopSheet,
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.df,
            right: AppSpacing.df,
            top: AppSpacing.df,
            bottom: bottomPadding + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: AppSpacing.borderRadiusXs,
            ),
          ),
          AppSpacing.verticalLg,
          
          // Title
          Text(
            l10n.security_changePassword,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalLg,
          
          // Old Password
          AppPasswordField(
            controller: _oldPasswordController,
            label: l10n.security_oldPassword,
            onChanged: (_) => setState(() {}),
          ),
          AppSpacing.verticalDf,
          
          // New Password
          AppPasswordField(
            controller: _newPasswordController,
            label: l10n.security_newPassword,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.auth_passwordRule,
              style: TextStyle(
                fontSize: 12,
                color: _newPasswordController.text.isNotEmpty &&
                        !isPasswordValid(_newPasswordController.text)
                    ? AppColors.error
                    : AppColors.grey,
              ),
            ),
          ),
          AppSpacing.verticalDf,
          
          // Confirm Password
          AppPasswordField(
            controller: _confirmPasswordController,
            label: l10n.security_confirmPassword,
            onChanged: (_) => setState(() {}),
          ),
          AppSpacing.verticalXl,
          
          // Submit Button
          AppPrimaryButton(
            text: l10n.common_save,
            isLoading: _isSubmitting,
            onPressed: _isFormValid && !_isSubmitting ? _handleSubmit : null,
          ),
        ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppToast.showError(context, l10n.security_passwordsDoNotMatch);
      return;
    }
    if (!isPasswordValid(_newPasswordController.text)) {
      AppToast.showError(context, l10n.auth_passwordRule);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tokens = await ref.read(authRepositoryProvider).changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      // Server bumped token_version (revoking other sessions); persist the
      // fresh tokens so this device stays signed in.
      final storage = ref.read(authStorageServiceProvider);
      await storage.setAccessToken(tokens.accessToken);
      await storage.setRefreshToken(tokens.refreshToken);

      if (!mounted) return;
      Navigator.pop(context);
      AppToast.showSuccess(context, l10n.security_passwordChangedSuccess);
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, l10n.security_changePasswordFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
