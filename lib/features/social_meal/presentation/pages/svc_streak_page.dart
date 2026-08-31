import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/meal_badge.dart';
import '../../domain/entities/meal_streak.dart';
import '../../providers/meal_schedule_provider.dart';

class SVCStreakPage extends ConsumerWidget {
  const SVCStreakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final streakAsync = ref.watch(mealStreakProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(
        title: l10n.svc_mealStreak,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: streakAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(theme: theme),
        data: (streak) => _StreakBody(
          streak: streak,
          theme: theme,
          isDark: isDark,
          l10n: l10n,
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _StreakBody extends StatelessWidget {
  const _StreakBody({
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final MealStreak streak;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final badges = MealBadge.evaluateAll(streak.currentStreak);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Main Streak Display ──────────────────────────────────────
          _StreakHeroCard(
            streak: streak,
            theme: theme,
            isDark: isDark,
            l10n: l10n,
            onStartCta: () => context.go(AppRoutes.svcQrScan),
          ),

          const SizedBox(height: 16),

          // ─── Progress toward milestone ────────────────────────────────
          if (streak.nextMilestone != null)
            _MilestoneProgress(streak: streak, theme: theme, isDark: isDark, l10n: l10n),

          const SizedBox(height: 16),

          // ─── Stats row ────────────────────────────────────────────────
          _StatsRow(streak: streak, theme: theme, isDark: isDark, l10n: l10n),

          const SizedBox(height: 20),

          // ─── Info cards ───────────────────────────────────────────────
          _InfoCard(
            icon: AppIcons.check,
            color: AppColors.green,
            text: l10n.svc_honestCancelInfo,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: AppIcons.warning,
            color: AppColors.red,
            text: l10n.svc_noShowInfo,
            isDark: isDark,
            theme: theme,
          ),

          const SizedBox(height: 24),

          // ─── Badges ───────────────────────────────────────────────────
          _BadgesSection(
            badges: badges,
            theme: theme,
            isDark: isDark,
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}

// ─── Hero streak card ─────────────────────────────────────────────────────────

class _StreakHeroCard extends StatelessWidget {
  const _StreakHeroCard({
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.l10n,
    this.onStartCta,
  });

  final MealStreak streak;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback? onStartCta;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final hasStreak = streak.currentStreak > 0;
    final fireColor = hasStreak ? const Color(0xFFFF9500) : AppColors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Fire + big number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppIcon(
                AppIcons.flame,
                size: 48,
                color: fireColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${streak.currentStreak}',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasStreak ? fireColor : AppColors.grey,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasStreak
                ? l10n.svc_currentStreak
                : l10n.svc_noStreakYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Divider + best streak
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                AppIcons.trophy,
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.svc_bestStreak,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.svc_streakDays(streak.bestStreak),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),

          if (streak.currentStreak == 0) ...[
            const SizedBox(height: 14),
            Text(
              l10n.svc_startStreak,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onStartCta != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStartCta,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.svc_goToMealPass,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Milestone Progress ───────────────────────────────────────────────────────

class _MilestoneProgress extends StatelessWidget {
  const _MilestoneProgress({
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final MealStreak streak;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final nextMilestone = streak.nextMilestone!;
    final daysLeft = streak.daysToNextMilestone!;

    // Find the previous milestone to compute the progress window
    final milestones = MealStreak.milestones;
    final prevMilestone = milestones.lastWhere(
      (m) => m <= streak.currentStreak,
      orElse: () => 0,
    );
    final window = nextMilestone - prevMilestone;
    final progress = (streak.currentStreak - prevMilestone) / window;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  l10n.svc_nextMilestone(daysLeft),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$nextMilestone ${l10n.svc_streakDays(nextMilestone)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${streak.currentStreak} / $nextMilestone',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final MealStreak streak;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '${streak.totalReceived}',
              label: l10n.svc_totalReceived,
              color: AppColors.green,
              theme: theme,
              showDivider: true,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatCell(
              value: '${streak.totalCancelled}',
              label: l10n.svc_totalCancelled,
              color: AppColors.orange,
              theme: theme,
              showDivider: true,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _StatCell(
              value: '${streak.totalNoShows}',
              label: l10n.svc_noShows,
              color: AppColors.red,
              theme: theme,
              showDivider: false,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
    required this.showDivider,
    required this.isDark,
  });

  final String value;
  final String label;
  final Color color;
  final ThemeData theme;
  final bool showDivider;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(right: BorderSide(color: dividerColor))
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.grey,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
    required this.theme,
  });

  final AppIconData icon;
  final Color color;
  final String text;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badges Section ───────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({
    required this.badges,
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final List<MealBadge> badges;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.svc_badges,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _BadgeTile(
              badge: badge,
              locale: locale,
              theme: theme,
              isDark: isDark,
              l10n: l10n,
            );
          },
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.locale,
    required this.theme,
    required this.isDark,
    required this.l10n,
  });

  final MealBadge badge;
  final String locale;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF242424) : Colors.white;
    final borderColor = badge.isUnlocked
        ? AppColors.primary.withValues(alpha: 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06));

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: badge.isUnlocked ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Emoji circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.grey.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge.isUnlocked ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + streak requirement
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.nameFor(locale),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.isUnlocked
                        ? l10n.svc_streakDays(badge.requiredStreak)
                        : l10n.svc_streakRequired(badge.requiredStreak),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: badge.isUnlocked
                          ? AppColors.primary
                          : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AppIcons.error,
            size: 48,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load streak',
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
