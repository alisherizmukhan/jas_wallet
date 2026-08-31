import 'package:app_ui/app_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/biometric/biometric_providers.dart';
import '../../../user/presentation/providers/user_provider.dart';

import '../widgets/change_password_dialog.dart';
import '../widgets/change_pin_dialog.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _togglingFp = false;
  bool _togglingFace = false;
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final hasFingerprint = ref.watch(hasFingerprintProvider);
    final hasFaceId = ref.watch(hasFaceIdProvider);
    final fpEnabled = ref.watch(fingerprintEnabledProvider);
    final faceEnabled = ref.watch(faceIdEnabledProvider);

    final fpAvailable = hasFingerprint.valueOrNull ?? false;
    final faceAvailable = hasFaceId.valueOrNull ?? false;
    final hasBiometrics = fpAvailable || faceAvailable;

    final bgColor = isLight ? const Color(0xFFF2F2F7) : const Color(0xFF171717);
    final cardColor = isLight ? AppColors.white : AppColors.surfaceDark;
    final dividerColor = isLight ? AppColors.borderGrey : AppColors.borderDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppAppBar(
        showBackButton: true,
        title: l10n.security_title,
        backgroundColor: isLight ? const Color(0xFFF2F2F7) : const Color(0xFF1F1F1F),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Biometrics section ─────────────────────────────────────────
          if (hasBiometrics) ...[
            _SectionLabel(isLight: isLight, text: l10n.security_title),
            const SizedBox(height: 8),
            _SecurityCard(
              cardColor: cardColor,
              dividerColor: dividerColor,
              children: [
                if (fpAvailable)
                  _BiometricRow(
                    icon: AppIcons.faceId,
                    iconBg: const Color(0xFF34C759).withValues(alpha: 0.15),
                    iconColor: const Color(0xFF34C759),
                    title: l10n.security_biometric,
                    subtitle: l10n.security_fingerprintSubtitle,
                    value: fpEnabled.valueOrNull ?? false,
                    isLoading: _togglingFp,
                    showDivider: faceAvailable,
                    onChanged: (v) => _toggleFingerprint(v),
                  ),
                if (faceAvailable)
                  _BiometricRow(
                    icon: AppIcons.faceId,
                    iconBg: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    iconColor: const Color(0xFF007AFF),
                    title: l10n.security_faceId,
                    subtitle: l10n.security_faceIdSubtitle,
                    value: faceEnabled.valueOrNull ?? false,
                    isLoading: _togglingFace,
                    showDivider: false,
                    onChanged: (v) => _toggleFaceId(v),
                  ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // ── Authentication section ──────────────────────────────────────
          _SectionLabel(isLight: isLight, text: l10n.security_authenticationSection),
          const SizedBox(height: 8),
          _SecurityCard(
            cardColor: cardColor,
            dividerColor: dividerColor,
            children: [
              _ActionRow(
                icon: AppIcons.lock,
                iconBg: const Color(0xFF5856D6).withValues(alpha: 0.15),
                iconColor: const Color(0xFF5856D6),
                title: l10n.security_changePassword,
                showDivider: true,
                dividerColor: dividerColor,
                onTap: () => _showChangePasswordDialog(context),
              ),
              _ActionRow(
                icon: AppIcons.security,
                iconBg: const Color(0xFFFF9500).withValues(alpha: 0.15),
                iconColor: const Color(0xFFFF9500),
                title: l10n.security_changePin,
                showDivider: false,
                dividerColor: dividerColor,
                onTap: () => ChangePinDialog.show(context),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Danger zone ────────────────────────────────────────────────
          _SecurityCard(
            cardColor: cardColor,
            dividerColor: dividerColor,
            children: [
              _ActionRow(
                icon: AppIcons.delete,
                iconBg: AppColors.error.withValues(alpha: 0.12),
                iconColor: AppColors.error,
                title: l10n.editProfile_deleteAccount,
                titleColor: AppColors.error,
                showDivider: false,
                dividerColor: dividerColor,
                isDestructive: true,
                isLoading: _isDeletingAccount,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Toggle handlers ────────────────────────────────────────────────────────

  Future<void> _toggleFingerprint(bool enable) async {
    setState(() => _togglingFp = true);
    try {
      await ref.read(fingerprintEnabledProvider.notifier).setEnabled(enable);
      await ref.read(authProvider.notifier).syncBiometricPreference();
    } finally {
      if (mounted) setState(() => _togglingFp = false);
    }
  }

  Future<void> _toggleFaceId(bool enable) async {
    setState(() => _togglingFace = true);
    try {
      await ref.read(faceIdEnabledProvider.notifier).setEnabled(enable);
      await ref.read(authProvider.notifier).syncBiometricPreference();
    } finally {
      if (mounted) setState(() => _togglingFace = false);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppPremiumDialog.show(
      context: context,
      icon: AppIcons.delete,
      iconColor: const Color(0xFFFF3B30),
      title: l10n.editProfile_deleteAccount,
      description: l10n.editProfile_deleteAccountDesc,
      confirmText: l10n.common_delete,
      cancelText: l10n.common_cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;
    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(userProvider.notifier).deleteAccount();
      final biometricService = ref.read(biometricAuthServiceProvider);
      await ref.read(authProvider.notifier).deleteAccount(
        biometricService: biometricService,
      );
      if (!mounted) return;
      context.go(AppRoutes.welcome);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.isLight});
  final String text;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Security card container ──────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.children,
    required this.cardColor,
    required this.dividerColor,
  });

  final List<Widget> children;
  final Color cardColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─── Biometric toggle row ─────────────────────────────────────────────────────

class _BiometricRow extends StatelessWidget {
  const _BiometricRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isLoading,
    required this.showDivider,
    required this.onChanged,
  });

  final AppIconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isLoading;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AppIcon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                CupertinoSwitch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary,
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
      ],
    );
  }
}

// ─── Action row (no toggle, just tap) ────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.showDivider,
    required this.dividerColor,
    required this.onTap,
    this.titleColor,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final AppIconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final bool showDivider;
  final Color dividerColor;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: AppIcon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  else if (!isDestructive)
                    AppIcon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: AppColors.grey,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 70, color: dividerColor),
      ],
    );
  }
}
