import 'package:app_ui/app_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../app_config/domain/models/app_config_model.dart';

// Canonical (ru) contest rules page; en/kk variants resolved at tap time via
// AppConfigModel.localizedUrl (https://jasaim.kz/{en|kk}/contest-rules).
const _kContestRulesUrl = 'https://jasaim.kz/contest-rules';
const _kInstagramUrl = 'https://instagram.com/blockchain.fintech.lab';
const _kInstagramUrl2 = 'https://instagram.com/nu_impact_foundation';

// ── Banner asset paths ─────────────────────────────────────────────────────────
const _kBannerHero     = 'assets/banners/contest_banners/champion.webp';
const _kBannerReferral = 'assets/banners/contest_banners/top_referrers.webp';
const _kBannerReel     = 'assets/banners/contest_banners/instagram.webp';
const _kBannerProfile  = 'assets/banners/contest_banners/most_creative.webp';

// ── Theme-independent accent constants ────────────────────────────────────────
const _kGold  = Color(0xFFFF9F0A);
const _kRose  = Color(0xFFFF2D55);
const _kGreen = Color(0xFF34C759);

const _kCardShadowLight = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 3)),
  BoxShadow(color: Color(0x07000000), blurRadius: 6,  offset: Offset(0, 1)),
];

// ── Per-render theme colour bundle ────────────────────────────────────────────

class _C {
  _C.of(BuildContext context) {
    final t = Theme.of(context);
    light    = t.brightness == Brightness.light;
    bg       = t.scaffoldBackgroundColor;
    card     = t.colorScheme.surface;
    text     = t.colorScheme.onSurface;
    textSec  = light ? const Color(0xFF6E6E73) : const Color(0xFF98989F);
    textTer  = light ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
    sep      = light ? const Color(0xFFE5E5EA) : const Color(0xFF333333);
    primary  = t.colorScheme.primary;
    priTint  = light ? const Color(0xFFF0E8FF) : const Color(0x26A78BFA);
    goldTint  = light ? const Color(0xFFFFF3E0) : _kGold.withValues(alpha: 0.14);
    roseTint  = light ? const Color(0xFFFFF0F5) : _kRose.withValues(alpha: 0.14);
    greenTint = light ? const Color(0xFFF0FFF4) : _kGreen.withValues(alpha: 0.14);
    shadow   = light ? _kCardShadowLight : const <BoxShadow>[];
  }

  late bool light;
  late Color bg;
  late Color card;
  late Color text;
  late Color textSec;
  late Color textTer;
  late Color sep;
  late Color primary;
  late Color priTint;
  late Color goldTint;
  late Color roseTint;
  late Color greenTint;
  late List<BoxShadow> shadow;
}

// ─────────────────────────────────────────────────────────────────────────────

class ContestPage extends StatelessWidget {
  const ContestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppAppBar(
        title: l10n.contest_title,
        showBackButton: true,
        showDivider: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _HeroSection(l10n: l10n),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _ContestCardsSection(l10n: l10n),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _HowItWorksSection(l10n: l10n),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _ConditionsSection(l10n: l10n),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _FaqSection(l10n: l10n),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: _FooterSection(l10n: l10n),
            ),
            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SecTitle extends StatelessWidget {
  const _SecTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: c.text,
        letterSpacing: -0.4,
        height: 1.1,
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(_kBannerHero, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.priTint,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 11, color: c.primary),
                      const SizedBox(width: 5),
                      Text(
                        l10n.referral_contestDeadline,
                        style: TextStyle(
                          color: c.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.contest_headline,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                      height: 1.06,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.contest_intro,
                  style: TextStyle(fontSize: 11, color: c.textSec, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contest cards ─────────────────────────────────────────────────────────────

class _ContestCardsSection extends StatelessWidget {
  const _ContestCardsSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecTitle(l10n.contest_title),
        const SizedBox(height: 14),
        _ContestCard(
          bannerAsset: _kBannerReferral,
          accentColor: _kGold,
          title: l10n.contest_card1Title,
          description: l10n.contest_card1Desc,
          prizes: const [
            _Prize('🥇', '₸50 000'),
            _Prize('🥈', '₸30 000'),
            _Prize('🥉', '₸20 000'),
          ],
          ctaLabel: l10n.referral_inviteFriends,
          ctaIcon: Icons.people_outline_rounded,
          onCtaTap: () => context.push(AppRoutes.referral),
        ),
        const SizedBox(height: 12),
        _ContestCard(
          bannerAsset: _kBannerReel,
          accentColor: _kRose,
          title: l10n.contest_card2Title,
          description: l10n.contest_card2Desc,
          prizes: const [
            _Prize('🏅', '₸100 000'),
          ],
          ctaLabel: '@blockchain.fintech.lab',
          ctaIcon: Icons.photo_camera_outlined,
          ctaIsInstagram: true,
          onCtaTap: () async {
            final uri = Uri.parse(_kInstagramUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          ctaLabel2: '@nu_impact_foundation',
          ctaIsInstagram2: true,
          onCtaTap2: () async {
            final uri = Uri.parse(_kInstagramUrl2);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        const SizedBox(height: 12),
        _ContestCard(
          bannerAsset: _kBannerProfile,
          accentColor: _kGold,
          title: l10n.contest_card3Title,
          description: l10n.contest_card3Desc,
          prizes: const [
            _Prize('🥇', '₸50 000'),
            _Prize('🥈', '₸30 000'),
            _Prize('🥉', '₸20 000'),
          ],
          note: l10n.contest_card3Note,
          ctaLabel: l10n.settings_myProfile,
          ctaIcon: Icons.person_outline_rounded,
          onCtaTap: () => context.push(AppRoutes.myProfile),
        ),
      ],
    );
  }
}

class _Prize {
  const _Prize(this.medal, this.amount);
  final String medal;
  final String amount;
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({
    required this.bannerAsset,
    required this.accentColor,
    required this.title,
    required this.description,
    this.prizes = const [],
    this.note,
    this.ctaLabel,
    this.ctaIcon,
    this.ctaIsInstagram = false,
    this.onCtaTap,
    this.ctaLabel2,
    this.ctaIsInstagram2 = false,
    this.onCtaTap2,
  });

  final String bannerAsset;
  final Color accentColor;
  final String title;
  final String description;
  final List<_Prize> prizes;
  final String? note;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final bool ctaIsInstagram;
  final VoidCallback? onCtaTap;
  final String? ctaLabel2;
  final bool ctaIsInstagram2;
  final VoidCallback? onCtaTap2;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: Image.asset(bannerAsset, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: c.textSec, height: 1.55),
                ),
                if (prizes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: c.sep),
                  const SizedBox(height: 12),
                  Text(
                    l10n.contest_prizePool.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: c.textTer,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prizes.map((p) => _PrizeRow(prize: p, accent: accentColor)),
                ],
                if (note != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 13, color: c.textTer),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            note!,
                            style: TextStyle(fontSize: 10, color: c.textSec, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (ctaLabel != null && onCtaTap != null) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: c.sep),
                  const SizedBox(height: 12),
                  _CtaButton(
                    label: ctaLabel!,
                    icon: ctaIcon ?? Icons.arrow_forward_rounded,
                    accent: accentColor,
                    isInstagram: ctaIsInstagram,
                    onTap: onCtaTap!,
                  ),
                  if (ctaLabel2 != null && onCtaTap2 != null) ...[
                    const SizedBox(height: 8),
                    _CtaButton(
                      label: ctaLabel2!,
                      icon: ctaIcon ?? Icons.arrow_forward_rounded,
                      accent: accentColor,
                      isInstagram: ctaIsInstagram2,
                      onTap: onCtaTap2!,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.prize, required this.accent});
  final _Prize prize;
  final Color accent;

  static Color _colorFor(String medal, Color fallback) {
    if (medal == '🥇') return const Color(0xFFFF9F0A);
    if (medal == '🥈') return const Color(0xFF8E8E93);
    if (medal == '🥉') return const Color(0xFFB87333);
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Text(prize.medal, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 8),
          Text(
            prize.amount,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _colorFor(prize.medal, accent),
              letterSpacing: -0.6,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA button ────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isInstagram = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isInstagram;

  static const _igStart = Color(0xFFF58529);
  static const _igMid   = Color(0xFFDD2A7B);
  static const _igEnd   = Color(0xFF8134AF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: isInstagram
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  colors: [_igStart, _igMid, _igEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _igMid.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: accent.withValues(alpha: 0.08),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isInstagram) ...[
              _IgIcon(),
              const SizedBox(width: 8),
            ] else ...[
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isInstagram ? Colors.white : accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: isInstagram ? Colors.white.withValues(alpha: 0.85) : accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _IgIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Center(
        child: _InstagramIcon(size: 12, color: Colors.white),
      ),
    );
  }
}

class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _InstagramIconPainter(color: color),
    );
  }
}

class _InstagramIconPainter extends CustomPainter {
  const _InstagramIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.07, h * 0.07, w * 0.86, h * 0.86),
        Radius.circular(w * 0.26),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, stroke);
    canvas.drawCircle(
      Offset(w * 0.73, h * 0.27),
      w * 0.075,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _InstagramIconPainter old) => old.color != color;
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecTitle(l10n.referral_howItWorksTitle),
        const SizedBox(height: 12),
        _StepCard(step: 1, icon: Icons.person_add_outlined,   title: l10n.referral_step1Title, desc: l10n.referral_step1Desc),
        const SizedBox(height: 8),
        _StepCard(step: 2, icon: Icons.download_rounded,      title: l10n.referral_step2Title, desc: l10n.referral_step2Desc),
        const SizedBox(height: 8),
        _StepCard(step: 3, icon: Icons.emoji_events_outlined, title: l10n.referral_step3Title, desc: l10n.referral_step3Desc),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
  });

  final int step;
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.shadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.priTint, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(color: c.primary, fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(icon, size: 13, color: c.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(desc, style: TextStyle(fontSize: 11, color: c.textSec, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conditions section ────────────────────────────────────────────────────────

class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecTitle(l10n.contest_condSectionTitle),
        const SizedBox(height: 12),
        _RuleCard(icon: Icons.people_outline_rounded,  iconColor: c.primary, iconBg: c.priTint,   title: l10n.contest_cond1Title,     desc: l10n.contest_cond1Desc),
        const SizedBox(height: 8),
        _RuleCard(icon: Icons.alternate_email_rounded, iconColor: _kRose,    iconBg: c.roseTint,  title: l10n.contest_mandatoryLabel, desc: l10n.contest_mandatoryDesc, isImportant: true),
        const SizedBox(height: 8),
        _RuleCard(icon: Icons.calendar_today_outlined, iconColor: _kGold,    iconBg: c.goldTint,  title: l10n.contest_cond3Title,     desc: l10n.referral_contestDeadline),
        const SizedBox(height: 8),
        _RuleCard(icon: Icons.emoji_events_outlined,   iconColor: c.primary, iconBg: c.priTint,   title: l10n.contest_cond4Title,     desc: l10n.contest_cond4Desc),
        const SizedBox(height: 8),
        _RuleCard(icon: Icons.notifications_outlined,  iconColor: _kGreen,   iconBg: c.greenTint, title: l10n.contest_cond5Title,     desc: l10n.contest_announcement),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.desc,
    this.isImportant = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String desc;
  final bool isImportant;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.shadow,
        border: isImportant ? Border.all(color: _kRose.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, size: 16, color: iconColor)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.text, height: 1.3)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 11, color: c.textSec, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ section ───────────────────────────────────────────────────────────────

class _FaqSection extends StatefulWidget {
  const _FaqSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<_FaqSection> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);
    final l10n = widget.l10n;
    final items = [
      (l10n.contest_faq1Q, l10n.contest_faq1A),
      (l10n.contest_faq2Q, l10n.contest_faq2A),
      (l10n.contest_faq3Q, l10n.contest_faq3A),
      (l10n.contest_faq4Q, l10n.contest_faq4A),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SecTitle(l10n.referral_faqTitle),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: c.shadow,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++)
                _FaqTile(
                  question: items[i].$1,
                  answer: items[i].$2,
                  isExpanded: _expanded.contains(i),
                  isLast: i == items.length - 1,
                  onTap: () => setState(() {
                    if (_expanded.contains(i)) {
                      _expanded.remove(i);
                    } else {
                      _expanded.add(i);
                    }
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.isLast,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.text, height: 1.35),
                  ),
                ),
                const SizedBox(width: 9),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.textTer),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(answer, style: TextStyle(fontSize: 11, color: c.textSec, height: 1.55)),
          ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: c.sep, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _FooterSection extends StatelessWidget {
  const _FooterSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final c = _C.of(context);
    final rulesUrl = AppConfigModel.localizedUrl(
      _kContestRulesUrl,
      Localizations.localeOf(context).languageCode,
    );

    return Column(
      children: [
        Text(
          l10n.contest_announcement,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textSec, height: 1.4),
        ),
        const SizedBox(height: 14),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: c.textTer, fontSize: 10, height: 1.5),
            children: [
              TextSpan(text: l10n.contest_legalPrefix),
              TextSpan(
                text: l10n.contest_legalLink,
                style: TextStyle(
                  color: c.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: c.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final uri = Uri.parse(rulesUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}
