import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../app_config/domain/models/app_config_model.dart';
import '../../../app_config/presentation/providers/app_config_provider.dart';
import '../../../tutorial/data/tutorial_service.dart';
import '../../../tutorial/domain/tutorial_content.dart';
import '../../../tutorial/domain/tutorial_ids.dart';
import '../../../tutorial/presentation/pages/tutorial_story_page.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/referral_model.dart';
import '../providers/referral_provider.dart';

class ReferralPage extends ConsumerStatefulWidget {
  const ReferralPage({super.key});

  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
  /// Whether the first-launch tutorial overlay is currently shown. Decided
  /// synchronously in initState so it covers the first frame (no flash) while
  /// the page loads behind it.
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackReferralScreenOpened();
    _showTutorial = TutorialService.instance.shouldShowSync(TutorialIds.referral);
    if (_showTutorial) {
      TutorialService.instance.markSeenSync(TutorialIds.referral);
    }
    // Pull fresh code/count + leaderboard each time the screen opens, since the
    // providers are cached for the app lifetime.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(referralProvider.notifier).refresh();
      ref.invalidate(leaderboardProvider);
    });
  }

  Widget _withTutorial(Widget page) {
    if (!_showTutorial) return page;
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) setState(() => _showTutorial = false);
            },
            child: TutorialStoryPage(
              tutorialId: TutorialIds.referral,
              slides: TutorialContent.referral(l10n),
              onDismiss: () => setState(() => _showTutorial = false),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final referralAsync = ref.watch(referralProvider);
    final configAsync = ref.watch(appConfigProvider);

    final Widget scaffold = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.referral_title,
        showBackButton: true,
        showDivider: false,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (_, _) => Center(
          child: Text(
            AppLocalizations.of(context)!.common_error,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          ),
        ),
        data: (referral) {
          final config = configAsync.valueOrNull ?? AppConfigModel.fallback;
          return _ReferralBody(referral: referral, config: config);
        },
      ),
    );
    return _withTutorial(scaffold);
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ReferralBody extends ConsumerWidget {
  const _ReferralBody({required this.referral, required this.config});

  final ReferralModel referral;
  final AppConfigModel config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(leaderboardProvider);
        await ref.read(referralProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCodeCard(referral: referral, config: config),
            const SizedBox(height: 20),
            _StatsRow(referral: referral, isLight: isLight),
            const SizedBox(height: 24),
            _SectionLabel(label: l10n.referral_leaderboardTitle),
            const SizedBox(height: 10),
            leaderboardAsync.when(
              loading: () =>
                  const SizedBox(height: 60, child: Center(child: AppLoader())),
              error: (_, _) => const SizedBox(),
              data: (entries) => entries.isEmpty
                  ? const SizedBox()
                  : _Leaderboard(entries: entries, isLight: isLight),
            ),
            const SizedBox(height: 24),
            _ContestSection(isLight: isLight),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Hero code card (Revolut style) ────────────────────────────────────────────

class _HeroCodeCard extends StatelessWidget {
  const _HeroCodeCard({required this.referral, required this.config});

  final ReferralModel referral;
  final AppConfigModel config;

  static const _cardBg = Color(0xFF0B0D14);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          Text(
            l10n.referral_yourCode.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.38),
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // Code — the hero
          Text(
            referral.referralCode,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 10),

          // Friends count inline
          _FriendsChip(count: referral.invitedFriendsCount),

          const SizedBox(height: 24),

          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: l10n.referral_copyCode,
                  icon: AppIcons.copy,
                  primary: false,
                  onTap: () => _copyCode(context, l10n),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: l10n.referral_shareInvite,
                  icon: AppIcons.share,
                  primary: true,
                  onTap: () => _shareCode(context, l10n),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(BuildContext context, AppLocalizations l10n) async {
    AnalyticsService.instance.trackReferralCodeCopied();
    await Clipboard.setData(ClipboardData(text: referral.referralCode));
    if (context.mounted) {
      AppToast.showSuccess(context, l10n.referral_codeCopied);
    }
  }

  Future<void> _shareCode(BuildContext context, AppLocalizations l10n) async {
    AnalyticsService.instance.trackReferralShareClicked();
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.zero;
      await SharePlus.instance.share(
        ShareParams(
          text: config.buildShareMessage(
            referralCode: referral.referralCode,
            languageCode: Localizations.localeOf(context).languageCode,
          ),
          title: l10n.referral_title,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (context.mounted) AppToast.showError(context, l10n.common_error);
    }
  }
}

class _FriendsChip extends StatelessWidget {
  const _FriendsChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AppIcons.users,
            size: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            '$count ${count == 1 ? 'friend' : 'friends'} joined',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final AppIconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              icon,
              size: 14,
              color: primary ? _HeroCodeCard._cardBg : Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: primary ? _HeroCodeCard._cardBg : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.referral, required this.isLight});

  final ReferralModel referral;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = referral.currentLevel;

    return Column(
      children: [
        _StatTile(
          isLight: isLight,
          value: '${referral.invitedFriendsCount}',
          label: l10n.referral_invitedFriends,
          icon: AppIcons.users,
          isLevel: false,
        ),
        const SizedBox(height: 12),
        _StatTile(
          isLight: isLight,
          value: current?.name ?? '—',
          label: current != null
              ? l10n.referral_currentLevel(current.name)
              : l10n.referral_noLevelYet,
          icon: AppIcons.token,
          isLevel: current != null,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.isLight,
    required this.value,
    required this.label,
    required this.icon,
    required this.isLevel,
  });

  final bool isLight;
  final String value;
  final String label;
  final AppIconData icon;
  final bool isLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: HomeShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isLight
                  ? AppColors.primaryLight
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(icon, size: 18, color: icon is SvgIcon ? null : AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isLevel ? 14 : 22,
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.grey,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.entries, required this.isLight});

  final List<LeaderboardEntry> entries;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: HomeShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            _LeaderboardRow(rank: i + 1, entry: entries[i], isLight: isLight),
            if (i < entries.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: isLight
                    ? AppColors.borderGrey.withValues(alpha: 0.5)
                    : AppColors.borderDark.withValues(alpha: 0.5),
                indent: 64,
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isLight,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = entry.isCurrentUser;

    return Container(
      color: isMe
          ? (isLight
                ? AppColors.primaryLight
                : AppColors.primary.withValues(alpha: 0.1))
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: rank <= 3
                ? Text(
                    rank == 1
                        ? '🥇'
                        : rank == 2
                        ? '🥈'
                        : '🥉',
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$rank',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          _Avatar(entry: entry, isMe: isMe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    color: isMe ? AppColors.primary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isMe)
                  Text(
                    'You',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.referralCount}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isMe ? AppColors.primary : null,
                ),
              ),
              const SizedBox(width: 4),
              AppIcon(
                AppIcons.users,
                size: 14,
                color: isMe ? AppColors.primary : AppColors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.isMe});
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final url = entry.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          // Matches the equivalent leaderboard avatar in
          // svc_leaderboard_page.dart — decode at a fixed small size
          // instead of the source photo's full resolution.
          memCacheWidth: 100,
          memCacheHeight: 100,
          errorWidget: (_, _, _) => _Initials(entry: entry, isMe: isMe),
          placeholder: (_, _) => _Initials(entry: entry, isMe: isMe),
        ),
      );
    }
    return _Initials(entry: entry, isMe: isMe);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.entry, required this.isMe});
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary
            : AppColors.grey.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          entry.initials,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isMe ? Colors.white : AppColors.grey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Contest section ───────────────────────────────────────────────────────────

class _ContestSection extends StatelessWidget {
  const _ContestSection({required this.isLight});
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surface = isLight ? Colors.white : const Color(0xFF242424);
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.contest_title),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: _ReferralPrizesItem(theme: theme, isLight: isLight, l10n: l10n),
        ),
      ],
    );
  }
}

class _ReferralPrizesItem extends StatefulWidget {
  const _ReferralPrizesItem({
    required this.theme,
    required this.isLight,
    required this.l10n,
  });
  final ThemeData theme;
  final bool isLight;
  final AppLocalizations l10n;

  @override
  State<_ReferralPrizesItem> createState() => _ReferralPrizesItemState();
}

class _ReferralPrizesItemState extends State<_ReferralPrizesItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isLight
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.token, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.l10n.contest_card1Title,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: AppIcon(
                        AppIcons.chevronDown,
                        size: 20,
                        color: AppColors.grey.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, left: 30),
                          child: AnimatedOpacity(
                            opacity: _expanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PrizeRow(rank: 1, amount: '₸50 000', theme: widget.theme),
                                const SizedBox(height: 6),
                                _PrizeRow(rank: 2, amount: '₸30 000', theme: widget.theme),
                                const SizedBox(height: 6),
                                _PrizeRow(rank: 3, amount: '₸20 000', theme: widget.theme),
                                const SizedBox(height: 10),
                                Divider(height: 1, color: borderColor),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    AppIcon(AppIcons.time, size: 14, color: AppColors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.l10n.referral_contestDeadline,
                                      style: widget.theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeRow extends StatelessWidget {
  const _PrizeRow({required this.rank, required this.amount, required this.theme});
  final int rank;
  final String amount;
  final ThemeData theme;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_medals[rank - 1], style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.grey,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
