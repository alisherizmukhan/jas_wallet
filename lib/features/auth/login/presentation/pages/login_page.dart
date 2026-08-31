import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../../core/analytics/analytics_service.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/utils/jwt_utils.dart';
import '../../../../auth/biometric/biometric_providers.dart';
import '../../../presentation/providers/auth_repository_provider.dart';

/// Login page with username/password form.
/// Biometric/PIN local auth is handled by the session unlock flow, not here.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialLogin});

  final String? initialLogin;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialLogin?.trim() ?? '';
    // NOTE: Biometric is intentionally NOT triggered here.
    //
    // REASON: If user has valid session (refresh token + PIN), they should
    // never see the login screen. Session validation happens in AuthNotifier
    // during app startup, which routes to PinVerifyPage (with biometric).
    //
    // If user reaches this LoginPage, they have NO valid session and must
    // enter credentials. After successful login the app stores refresh token
    // in secure storage; future unlock happens via PIN/biometric + refresh.
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _usernameController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty;

  // ─── Manual login ────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);
    await _performLogin(_usernameController.text.trim(), _passwordController.text.trim());
  }

  // ─── Core login logic ─────────────────────────────────────────────────
  Future<void> _performLogin(String username, String password) async {
    AnalyticsService.instance.trackLoginStarted();
    try {
      final tokens = await ref.read(authRepositoryProvider).login(
        username.trim(),
        password,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;

      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      // Migration cleanup: old versions stored login/password for biometric auth.
      // Bank-style flow uses refresh token only, so wipe legacy credential cache.
      await ref.read(biometricAuthServiceProvider).clearCredentials();

      final userId = decodeJwtSubject(tokens.accessToken) ?? username.trim();
      AnalyticsService.instance.trackLoginSuccess(userId: userId);
      await ref.read(authProvider.notifier).login(
        userId: userId,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AnalyticsService.instance.trackLoginFailed(errorType: e.runtimeType.toString());
      AppToast.showError(
        context,
        e.toString().replaceFirst('AuthException: ', ''),
      );
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        showBackButton: true,
        showDivider: false,
        onBackPressed: () => context.go(AppRoutes.welcome),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          l10n.auth_login,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLight ? AppColors.textColor : AppColors.textColorDark,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          l10n.auth_loginDesc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username field
                        _InputField(
                          fieldKey: const Key('loginUsernameField'),
                          controller: _usernameController,
                          hintText: l10n.auth_usernameOrEmail,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _InputField(
                          fieldKey: const Key('loginPasswordField'),
                          controller: _passwordController,
                          hintText: l10n.auth_password,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          suffixIcon: IconButton(
                            key: const Key('loginPasswordToggle'),
                            tooltip: _obscurePassword
                                ? l10n.common_showPassword
                                : l10n.common_hidePassword,
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            icon: AppIcon(
                              _obscurePassword
                                  ? AppIcons.visibilityOff
                                  : AppIcons.visibility,
                              color: AppColors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Forgot password (right-aligned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => context.push(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.auth_forgotPassword,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                ),
                              ),
                            ),
                        ),

                        const Spacer(),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            key: const Key('loginButton'),
                            onPressed: _isValid && !_isLoading ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isValid
                                  ? AppColors.primary
                                  : isLight
                                      ? AppColors.secondary
                                      : AppColors.surfaceDark,
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
                                    l10n.common_continue,
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
            );
          },
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
  final Key? fieldKey;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.fieldKey,
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
        key: fieldKey,
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          color: isLight ? AppColors.textColor : AppColors.textColorDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 16, color: AppColors.grey),
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
