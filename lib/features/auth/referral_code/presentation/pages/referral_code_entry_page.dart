import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import 'package:app_ui/app_ui.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../referral/presentation/providers/referral_provider.dart';
import '../../data/pending_referral_service.dart';

/// Optional referral code entry shown between profile creation and Salto activation.
///
/// Tries to attribute the code immediately (the account already has a session
/// after profile completion). The code is also stashed via
/// [PendingReferralService] so the auth listener can retry once the session is
/// fully established, then cleared on success.
class ReferralCodeEntryPage extends ConsumerStatefulWidget {
  const ReferralCodeEntryPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ReferralCodeEntryPage> createState() =>
      _ReferralCodeEntryPageState();
}

class _ReferralCodeEntryPageState extends ConsumerState<ReferralCodeEntryPage> {
  final _codeController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _trimmedCode => _codeController.text.trim().toUpperCase();

  bool get _isCodeValid {
    final code = _trimmedCode;
    return code.length >= 3 && code.length <= 10;
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isCodeValid) {
      AppToast.showError(context, l10n.referral_invalidCodeFormat);
      return;
    }

    final code = _trimmedCode;
    setState(() => _isSaving = true);
    // Stash first so the auth listener can retry if the session isn't ready yet.
    await PendingReferralService.save(code);

    String message = l10n.referral_codeApplied;
    try {
      await ref.read(referralRepositoryProvider).redeemCode(code: code);
      await PendingReferralService.clear();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 400 self-referral / 404 unknown / 409 already applied → terminal,
      // don't keep retrying. Onboarding continues regardless.
      if (status == 400 || status == 404 || status == 409) {
        await PendingReferralService.clear();
        message = l10n.referral_invalidCodeFormat;
      }
      // Other errors (network/401): keep pending; the auth listener retries.
    } catch (_) {
      // Keep pending for retry.
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    AppToast.showSuccess(context, message);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _goToSalto();
  }

  void _skip() => _goToSalto();

  void _goToSalto() {
    context.pushReplacement(
      AppRoutes.saltoActivation,
      extra: {'userId': widget.userId},
    );
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Icon badge
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isLight
                                ? AppColors.primaryLight
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.gift,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          l10n.referral_enterCodeTitle,
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
                          l10n.referral_enterCodeDesc,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Code input
                        Container(
                          decoration: BoxDecoration(
                            color: isLight
                                ? AppColors.fieldBackground
                                : AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(10),
                              _UpperCaseFormatter(),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: isLight
                                  ? AppColors.black
                                  : AppColors.textPrimaryDark,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.referral_codeFieldHint,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                color: AppColors.grey.withValues(alpha: 0.7),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: AppIcon(
                                  AppIcons.copy,
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

                        const Spacer(),

                        // Apply Code button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isCodeValid && !_isSaving
                                ? _apply
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCodeValid
                                  ? AppColors.primary
                                  : isLight
                                  ? AppColors.secondary
                                  : AppColors.surfaceDark,
                              foregroundColor: _isCodeValid
                                  ? AppColors.white
                                  : AppColors.primary.withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.referral_applyCode,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Skip button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: _skip,
                            child: Text(
                              l10n.referral_skipStep,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
