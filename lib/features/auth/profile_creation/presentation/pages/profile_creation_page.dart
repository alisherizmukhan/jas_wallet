import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../../core/analytics/analytics_service.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/utils/password_policy.dart';
import '../../../../../core/utils/username_input_formatter.dart';
import '../../../../user/presentation/providers/user_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../presentation/providers/auth_repository_provider.dart';

/// User Information page - Step after OTP verification.
/// Design: Title, Description, First Name, Last Name, Password,
/// Confirm Password, Phone (optional).
///
/// After filling required fields → creates profile and continues onboarding.
class ProfileCreationPage extends ConsumerStatefulWidget {
  const ProfileCreationPage({super.key});

  @override
  ConsumerState<ProfileCreationPage> createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends ConsumerState<ProfileCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLookingUpStudentId = false;
  String? _studentIdError;
  String? _resolvedStudentId;
  Timer? _studentIdLookupDebounce;

  // Username availability
  bool _isCheckingUsername = false;
  bool _usernameAvailable = false;
  String? _usernameError;
  Timer? _usernameCheckDebounce;

  static const _studentIdLookupDelay = Duration(milliseconds: 450);
  static const _minStudentIdLength = 6;
  static const _usernameCheckDelay = Duration(milliseconds: 400);
  static const _minUsernameLength = 3;
  static const _maxUsernameLength = 30;

  bool get _isPasswordFormatValid => isPasswordValid(_passwordController.text);

  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;

  @override
  void dispose() {
    _studentIdLookupDebounce?.cancel();
    _usernameCheckDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _hasResolvedStudentIdentity &&
        _usernameAvailable &&
        _isPasswordFormatValid &&
        _passwordsMatch;
  }

  bool get _hasResolvedStudentIdentity {
    final studentId = _studentIdController.text.trim();
    return !_isLookingUpStudentId &&
        _studentIdError == null &&
        _resolvedStudentId == studentId &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
  }

  void _clearResolvedStudentIdentity({String? error}) {
    _resolvedStudentId = null;
    _studentIdError = error;
    _firstNameController.clear();
    _lastNameController.clear();
  }

  void _onStudentIdChanged(String value) {
    final studentId = value.trim();
    _studentIdLookupDebounce?.cancel();

    final resolvedStudentChanged = _resolvedStudentId != null && _resolvedStudentId != studentId;
    if (resolvedStudentChanged) {
      _clearResolvedStudentIdentity();
    }

    if (studentId.isEmpty) {
      setState(() {
        _isLookingUpStudentId = false;
        _clearResolvedStudentIdentity();
      });
      return;
    }

    if (studentId.length < _minStudentIdLength) {
      setState(() {
        _isLookingUpStudentId = false;
        _clearResolvedStudentIdentity();
      });
      return;
    }

    setState(() {
      _isLookingUpStudentId = true;
      _studentIdError = null;
    });

    _studentIdLookupDebounce = Timer(_studentIdLookupDelay, () {
      _lookupStudentId(studentId);
    });
  }

  Future<void> _lookupStudentId(
    String rawStudentId, {
    bool showToastOnError = false,
  }) async {
    final studentId = rawStudentId.trim();
    if (studentId.length < _minStudentIdLength) {
      if (!mounted) return;
      setState(() {
        _isLookingUpStudentId = false;
        _clearResolvedStudentIdentity();
      });
      return;
    }

    try {
      final result = await ref.read(authRepositoryProvider).lookupStudentId(studentId);
      if (!mounted || _studentIdController.text.trim() != studentId) return;

      // The student ID resolves, but it already belongs to another registered
      // account — block it so a user can't claim someone else's SALTO access.
      if (result.alreadyRegistered) {
        setState(() {
          _isLookingUpStudentId = false;
          _clearResolvedStudentIdentity(
            error: AppLocalizations.of(context)!.auth_studentIdTaken,
          );
        });
        return;
      }

      setState(() {
        _isLookingUpStudentId = false;
        _studentIdError = null;
        _resolvedStudentId = result.studentId;
        _firstNameController.text = result.firstName;
        _lastNameController.text = result.lastName;
      });
    } catch (e) {
      if (!mounted || _studentIdController.text.trim() != studentId) return;
      final message = e.toString().replaceFirst('AuthException: ', '');
      setState(() {
        _isLookingUpStudentId = false;
        _clearResolvedStudentIdentity(error: message);
      });
      if (showToastOnError) {
        AppToast.showError(context, message);
      }
    }
  }

  void _onUsernameChanged(String value) {
    _usernameCheckDebounce?.cancel();
    final username = value.trim().toLowerCase();

    // Any edit invalidates the previous availability result.
    setState(() => _usernameAvailable = false);

    if (username.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = null;
      });
      return;
    }

    // Too short / too long: keep the button disabled silently (the input
    // formatter already restricts the allowed characters).
    if (username.length < _minUsernameLength ||
        username.length > _maxUsernameLength) {
      setState(() {
        _isCheckingUsername = false;
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _usernameCheckDebounce =
        Timer(_usernameCheckDelay, () => _checkUsername(username));
  }

  Future<void> _checkUsername(String username) async {
    try {
      final result =
          await ref.read(authRepositoryProvider).checkUsernameAvailable(username);
      // Ignore stale responses if the field changed while the request was in flight.
      if (!mounted ||
          _usernameController.text.trim().toLowerCase() != username) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isCheckingUsername = false;
        if (!result.valid) {
          _usernameAvailable = false;
          _usernameError = l10n.auth_usernameInvalidFormat;
        } else if (!result.available) {
          _usernameAvailable = false;
          _usernameError = l10n.auth_usernameTaken;
        } else {
          _usernameAvailable = true;
          _usernameError = null;
        }
      });
    } catch (_) {
      if (!mounted ||
          _usernameController.text.trim().toLowerCase() != username) {
        return;
      }
      // Network/availability check failed — don't show a misleading error,
      // just leave the username unconfirmed so submit stays disabled.
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailable = false;
        _usernameError = null;
      });
    }
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasResolvedStudentIdentity) {
      await _lookupStudentId(
        _studentIdController.text,
        showToastOnError: true,
      );
      if (!_hasResolvedStudentIdentity) {
        return;
      }
    }

    setState(() => _isLoading = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final studentId = _studentIdController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();

    ref.read(userProvider.notifier).updateProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      studentId: studentId,
      phone: phone,
    );

    try {
      final userId = await ref.read(authRepositoryProvider).completeProfile(
        firstName: firstName,
        lastName: lastName,
        nuStudentId: studentId,
        username: username,
        password: _passwordController.text,
        phone: phone,
        consentVersion: kPersonalDataConsentVersion,
      );

      // Registration is now complete: the account has a password and a full
      // profile, so the half-created session guard can be released.
      await ref.read(authStorageServiceProvider).setRegistrationPending(false);

      if (!mounted) return;

      AnalyticsService.instance.trackRegistrationSuccess(userId: userId);

      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      context.pushReplacement(
        AppRoutes.referralCodeEntry,
        extra: {'userId': userId},
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        e.toString().replaceFirst('AuthException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.auth_createProfile,
        showBackButton: true,
        showDivider: false,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                // Description
                Text(
                  l10n.auth_createProfileDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey,
                  ),
                ),

                const SizedBox(height: 32),

                // Student ID field
                _InputField(
                  controller: _studentIdController,
                  hint: l10n.auth_studentIdHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: _onStudentIdChanged,
                  suffixIcon: _isLookingUpStudentId
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),

                if (_studentIdError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _studentIdError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ] else if (_hasResolvedStudentIdentity) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.auth_nameAutoFilled,
                    style: TextStyle(
                      color: isLight ? AppColors.textSecondary : AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // First Name field (auto-filled from university directory)
                _InputField(
                  controller: _firstNameController,
                  hint: l10n.auth_firstNameHint,
                  readOnly: true,
                ),

                const SizedBox(height: 16),

                // Last Name field (auto-filled from university directory)
                _InputField(
                  controller: _lastNameController,
                  hint: l10n.auth_lastNameHint,
                  readOnly: true,
                ),

                const SizedBox(height: 16),

                // Username field (3-30 chars, lowercase, digits, underscore)
                _InputField(
                  controller: _usernameController,
                  hint: l10n.auth_usernameHint,
                  inputFormatters: [UsernameInputFormatter()],
                  onChanged: _onUsernameChanged,
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_usernameAvailable
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: AppIcon(
                                AppIcons.check,
                                color: AppColors.success,
                              ),
                            )
                          : null),
                ),

                if (_usernameError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _usernameError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ] else if (_usernameAvailable) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.auth_usernameAvailable,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Phone field (optional)
                _InputField(
                  controller: _phoneController,
                  hint: l10n.auth_phoneOptional,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 16),

                // Password field
                _InputField(
                  controller: _passwordController,
                  hint: l10n.auth_createPassword,
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
                      _obscurePassword ? AppIcons.visibilityOff : AppIcons.visibility,
                      color: AppColors.grey,
                    ),
                  ),
                ),

                // Password rule hint — turns red when a non-empty password
                // does not meet the policy.
                const SizedBox(height: 8),
                Text(
                  l10n.auth_passwordRule,
                  style: TextStyle(
                    color: _passwordController.text.isNotEmpty &&
                            !_isPasswordFormatValid
                        ? AppColors.error
                        : (isLight ? AppColors.textSecondaryOnLight : AppColors.grey),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password field
                _InputField(
                  controller: _confirmPasswordController,
                  hint: l10n.auth_repeatPassword,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? l10n.common_showPassword
                        : l10n.common_hidePassword,
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    icon: AppIcon(
                      _obscureConfirmPassword ? AppIcons.visibilityOff : AppIcons.visibility,
                      color: AppColors.grey,
                    ),
                  ),
                ),

                if (_confirmPasswordController.text.isNotEmpty &&
                    !_passwordsMatch) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.auth_passwordsDoNotMatch,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Button pinned at bottom, independent of scroll content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _createProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? AppColors.primary
                        : isLight
                            ? AppColors.secondary
                            : AppColors.surfaceDark,
                    foregroundColor: _isFormValid
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
                          l10n.auth_createAccount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom input field matching the design.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.readOnly = false,
    this.onChanged,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
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
        onChanged: onChanged,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          fontSize: 16,
          color: isLight ? AppColors.textColor : AppColors.textColorDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: AppColors.grey.withValues(alpha: 0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
