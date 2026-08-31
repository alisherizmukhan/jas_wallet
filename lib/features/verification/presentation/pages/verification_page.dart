import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/jwt_utils.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';

/// OTP verification page.
/// Design: Back button, Title, Description with destination, 6 code boxes, Confirm button.
/// Flow: 'registration' — verify-otp API, save tokens, call onVerified.
///       'reset' — pass code to onVerifiedWithCode, navigate to reset password.
class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({
    super.key,
    required this.destination,
    required this.isPhone,
    this.flow = 'registration',
    this.onVerified,
    this.onVerifiedWithCode,
  });

  final String destination;
  final bool isPhone;
  final String flow;
  final VoidCallback? onVerified;
  final void Function(String code)? onVerifiedWithCode; // For reset flow

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _code {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isCodeComplete => _code.length == 6;

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      // Paste / SMS/email autocomplete — distribute all digits across cells.
      // Use addPostFrameCallback so we set controller text AFTER the TextField
      // has finished processing the current input event, avoiding conflicts.
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = i < digits.length ? digits[i] : '';
          _controllers[i].selection = TextSelection.collapsed(
            offset: _controllers[i].text.length,
          );
        }
        final focusIndex = (digits.length >= 6) ? 5 : digits.length.clamp(0, 5);
        _focusNodes[focusIndex].requestFocus();
        setState(() {});
      });
      return;
    }
    if (value.isEmpty) {
      // Backspace just cleared this box. Cascade focus to the previous box
      // immediately (rather than waiting for a second backspace press on an
      // already-empty box) so the user can hold/repeat backspace and delete
      // the whole code in one continuous motion, instead of having to tap
      // into each box individually. This is driven from onChanged — not the
      // KeyboardListener below — because soft keyboards (notably Android's)
      // generally don't emit a raw backspace KeyEvent for an already-empty
      // field, only real text-change events, so onChanged is the reliable
      // signal here.
      if (index > 0) {
        final previous = _controllers[index - 1];
        previous.selection = TextSelection.collapsed(
          offset: previous.text.length,
        );
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyPressed(int index, KeyEvent event) {
    // Fallback for physical/Bluetooth keyboards: if the user tabs/clicks into
    // an already-empty box and presses backspace there directly (no text
    // change to trigger onChanged), still cascade focus back.
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (!_isCodeComplete) return;

    setState(() => _isLoading = true);

    try {
      if (widget.flow == 'reset') {
        // Reset password flow: navigate to reset page with email and code
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.pop();
        context.push(
          AppRoutes.resetPassword,
          extra: {'email': widget.destination, 'code': _code},
        );
      } else {
        // Registration flow: verify OTP via API, save tokens for complete-profile
        final tokens = await ref.read(authRepositoryProvider).verifyOtp(
          widget.destination,
          _code,
        );
        final storage = ref.read(authStorageServiceProvider);
        // The verify-otp tokens already carry the real student UUID as their
        // subject; persist that instead of the email so the session is valid
        // for the complete-profile call. Mark the registration as pending so a
        // cold start before profile completion does not silently log the user
        // in (without a password / completed profile).
        final resolvedUserId =
            decodeJwtSubject(tokens.accessToken) ?? widget.destination;
        await storage.saveSession(
          userId: resolvedUserId,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
        );
        await storage.setRegistrationPending(true);
        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onVerified?.call();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(
        context,
        e.toString().replaceFirst('AuthException: ', ''),
      );
    }
  }

  void _resendCode() async {
    if (_resendSeconds > 0) return;
    _startResendTimer();
    try {
      if (widget.flow == 'reset') {
        await ref.read(authRepositoryProvider).forgotPassword(widget.destination);
      } else {
        await ref.read(authRepositoryProvider).sendOtp(widget.destination);
      }
    } catch (_) {
      // Silently ignore resend errors
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
        showBackButton: true,
        showDivider: false,
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
                          l10n.verification_title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLight ? AppColors.textColor : AppColors.textColorDark,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          l10n.verification_codeSent(widget.destination),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Code input boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _CodeBox(
                                key: Key('verificationCodeBox_$index'),
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                onChanged: (value) =>
                                    _onCodeChanged(index, value),
                                onKey: (event) => _onKeyPressed(index, event),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        // Resend code button
                        Center(
                          child: TextButton(
                            key: const Key('verificationResendButton'),
                            onPressed: _resendSeconds > 0 ? null : _resendCode,
                            child: Text(
                              _resendSeconds > 0
                                  ? l10n.verification_resendIn(_resendSeconds)
                                  : l10n.verification_resend,
                              style: TextStyle(
                                color: _resendSeconds > 0
                                    ? AppColors.grey
                                    : AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Confirm button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            key: const Key('verificationConfirmButton'),
                            onPressed: (_isCodeComplete && !_isLoading) ? _verify : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCodeComplete
                                  ? AppColors.primary
                                  : (isLight ? AppColors.secondary : AppColors.surfaceDark),
                              foregroundColor: _isCodeComplete
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
                                    l10n.common_confirm,
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

/// Single code input box.
class _CodeBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Function(KeyEvent) onKey;

  const _CodeBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isLight ? AppColors.textColor : AppColors.textColorDark,
            height: 1.0,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
