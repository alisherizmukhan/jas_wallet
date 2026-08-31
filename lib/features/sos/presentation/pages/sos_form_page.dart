import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analytics/analytics_mixpanel_provider.dart';
import '../../config/sos_config.dart';

const _kRed = Color(0xFFD7263D);

class SosFormPage extends ConsumerStatefulWidget {
  const SosFormPage({super.key});

  @override
  ConsumerState<SosFormPage> createState() => _SosFormPageState();
}

class _SosFormPageState extends ConsumerState<SosFormPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(analyticsServiceProvider).trackSosOpened();
    });
  }

  Future<void> _dial(BuildContext context, String number, String callTarget) async {
    await HapticFeedback.mediumImpact();
    final analytics = ref.read(analyticsServiceProvider);
    if (callTarget == '102') analytics.trackSosCall102Clicked();
    if (callTarget == '112') analytics.trackSosCall112Clicked();
    if (callTarget == 'campus') analytics.trackSosCallCampusSecurityClicked();

    final uri = SosConfig.telUri(number);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        AppToast.showError(context, AppLocalizations.of(context)!.sos_dialerUnavailable);
        analytics.trackSosDialerUnavailable(callTarget: callTarget);
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(context, AppLocalizations.of(context)!.sos_dialerUnavailable);
        analytics.trackSosDialerUnavailable(callTarget: callTarget);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final theme  = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppAppBar(title: l10n.sos_title, showBackButton: true, showDivider: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ──────────────────────────────────────────────────────
              _SosHero(l10n: l10n),
              const SizedBox(height: 28),

              // ── Section label ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  l10n.sos_emergencyActions.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              // ── Row 1 ────────────────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ServiceCard(
                        serviceName: l10n.sos_callPolice,
                        number: SosConfig.policeNumber,
                        icon: AppIcons.security,
                        isLight: isLight,
                        onTap: () => _dial(context, SosConfig.policeNumber, '102'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceCard(
                        serviceName: l10n.sos_callAmbulance,
                        number: SosConfig.ambulanceNumber,
                        icon: AppIcons.heartPulse,
                        isLight: isLight,
                        onTap: () => _dial(context, SosConfig.ambulanceNumber, '103'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Row 2 ────────────────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ServiceCard(
                        serviceName: l10n.sos_callFire,
                        number: SosConfig.fireNumber,
                        icon: AppIcons.flame,
                        isLight: isLight,
                        onTap: () => _dial(context, SosConfig.fireNumber, '101'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceCard(
                        serviceName: l10n.sos_callEmergency,
                        number: SosConfig.emergencyNumber,
                        icon: AppIcons.alertCircle,
                        isLight: isLight,
                        onTap: () => _dial(context, SosConfig.emergencyNumber, '112'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Hero banner
// ═══════════════════════════════════════════════════════════════════════════════

class _SosHero extends StatelessWidget {
  const _SosHero({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD7263D), Color(0xFFA01020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsing icon ring
          _PulsingIcon(),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sos_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sos_subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);
    _scale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: _opacity.value),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: AppIcon(AppIcons.call, size: 26, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Small service card (used in 3-column row)
// ═══════════════════════════════════════════════════════════════════════════════

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({
    required this.serviceName,
    required this.number,
    required this.icon,
    required this.isLight,
    required this.onTap,
  });

  final String serviceName;
  final String number;
  final AppIconData icon;
  final bool isLight;
  final VoidCallback onTap;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: widget.isLight ? AppColors.white : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            boxShadow: HomeShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(widget.icon, size: 20, color: _kRed),
                ),
              ),
              const SizedBox(height: 12),

              // Service name
              Text(
                widget.serviceName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.grey,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Number
              Text(
                widget.number,
                style: const TextStyle(
                  color: _kRed,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              // CALL button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  AppLocalizations.of(context)!.sos_callButton,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
