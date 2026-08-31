import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../../core/analytics/analytics_service.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../user/presentation/providers/user_provider.dart';
import '../../../presentation/providers/auth_repository_provider.dart';

/// Registration page - Step 1: Email input (university domain @nu.edu.kz).
class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _consentChecked = false;
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Valid when email matches @nu.edu.kz and consent is checked.
  bool get _isFormValid {
    return _isEmailValid(_emailController.text) && _consentChecked;
  }

  /// Email must be non-empty, valid format, and end with @nu.edu.kz.
  bool _isEmailValid(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@nu\.edu\.kz$');
    return regex.hasMatch(email);
  }

  void _validateEmail(String value) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (value.isEmpty) {
        _emailError = null;
      } else if (!value.contains('@')) {
        _emailError = l10n.auth_invalidEmailFormat;
      } else if (!_isEmailValid(value)) {
        _emailError = l10n.auth_onlyNuEmailAllowed;
      } else {
        _emailError = null;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentChecked) return;
    if (!_isEmailValid(_emailController.text)) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();

    AnalyticsService.instance.trackRegistrationStarted();

    // Save email to user provider
    ref.read(userProvider.notifier).updateProfile(email: email);

    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await ref.read(authRepositoryProvider).sendOtp(email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.alreadyRegistered) {
        AppToast.showInfo(
          context,
          l10n.auth_alreadyRegistered,
        );
        context.push(
          AppRoutes.login,
          extra: {'initialLogin': email},
        );
        return;
      }

      // Biometric.kz skipped — negotiating subscription. Flow: OTP → Profile Creation
      context.push(
        AppRoutes.verification,
        extra: {
          'destination': email,
          'isPhone': false,
          'flow': 'registration',
          'onVerified': () {
            context.pop();
            context.push(AppRoutes.profileCreation);
          },
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AnalyticsService.instance.trackRegistrationFailed(errorType: e.runtimeType.toString());
      final message = e.toString().replaceFirst('AuthException: ', '');
      AppToast.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(showBackButton: true, showDivider: false),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            l10n.auth_registration,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLight
                                  ? AppColors.black
                                  : AppColors.textPrimaryDark,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Description
                          Text(
                            l10n.auth_registrationDesc,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Email input
                          Container(
                            decoration: BoxDecoration(
                              color: isLight
                                  ? AppColors.fieldBackground
                                  : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _emailError != null
                                    ? AppColors.red
                                    : AppColors.fieldBackground,
                                width: 2.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: TextField(
                              key: const Key('registrationEmailField'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: _validateEmail,
                              style: TextStyle(
                                fontSize: 16,
                                color: isLight
                                    ? AppColors.black
                                    : AppColors.textPrimaryDark,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.auth_emailExample,
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.grey.withValues(alpha: 0.7),
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

                          const SizedBox(height: 24),

                          // Consent checkbox — text is clickable to open consent page
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  key: const Key('registrationConsentCheckbox'),
                                  value: _consentChecked,
                                  onChanged: (value) {
                                    setState(
                                      () => _consentChecked = value ?? false,
                                    );
                                  },
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(
                                    color: _consentChecked
                                        ? AppColors.primary
                                        : AppColors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Open personal data consent page
                                    context.push(AppRoutes.personalDataConsent);
                                  },
                                  child: Text(
                                    l10n.auth_consentDataCollection,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Register button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              key: const Key('registrationButton'),
                              onPressed: (_isFormValid && !_isLoading) ? _register : null,
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
                                      l10n.auth_register,
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
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Old phone-based registration code (commented out per requirements)
// ─────────────────────────────────────────────────────────────────────────────

// /// Phone input field with country code.
// class _PhoneInputField extends StatelessWidget {
//   final TextEditingController controller;
//   final ValueChanged<String>? onChanged;
//
//   const _PhoneInputField({required this.controller, this.onChanged});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.fieldBackground,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
//             child: Row(
//               children: [
//                 Container(
//                   width: 28, height: 28,
//                   decoration: BoxDecoration(
//                     color: AppColors.secondary,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Center(child: Icon(Icons.language, size: 16, color: AppColors.primary)),
//                 ),
//                 const SizedBox(width: 8),
//                 const Text('+7', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.black)),
//               ],
//             ),
//           ),
//           Container(width: 1, height: 24, color: AppColors.grey.withValues(alpha: 0.3)),
//           Expanded(
//             child: TextField(
//               controller: controller, onChanged: onChanged,
//               keyboardType: TextInputType.phone,
//               style: const TextStyle(fontSize: 16, color: AppColors.black, letterSpacing: 1.2),
//               inputFormatters: [FilteringTextInputFormatter.digitsOnly, _KazakhPhoneFormatter()],
//               decoration: InputDecoration(
//                 hintText: '123 456 78 90',
//                 hintStyle: TextStyle(fontSize: 16, color: AppColors.grey.withValues(alpha: 0.5), letterSpacing: 1.2),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// Formats phone number as XXX XXX XX XX (Kazakhstan format).
// class _KazakhPhoneFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
//     final buffer = StringBuffer();
//
//     for (var i = 0; i < digitsOnly.length && i < 10; i++) {
//       buffer.write(digitsOnly[i]);
//       if (i == 2 || i == 5 || i == 7) {
//         if (i < digitsOnly.length - 1) {
//           buffer.write(' ');
//         }
//       }
//     }
//
//     return TextEditingValue(
//       text: buffer.toString(),
//       selection: TextSelection.collapsed(offset: buffer.length),
//     );
//   }
// }
