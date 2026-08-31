import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/routing/app_router.dart';
import '../../core/utils/image_utils.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import '../../features/orientation_week/config/orientation_config.dart';
import '../../features/social_meal/providers/svc_meal_provider.dart';
import '../../features/tutorial/domain/tutorial_content.dart';
import '../../features/tutorial/domain/tutorial_ids.dart';
import '../../features/tutorial/domain/tutorial_slide.dart';
import '../../features/tutorial/presentation/pages/tutorial_story_page.dart';

import '../../features/user/presentation/providers/user_provider.dart';

/// Curated per-service accents from the design.md palette — each service
/// glyph carries a distinct, harmonious colour over a soft same-colour chip
/// (the accent lives in the iconography, never as a full tile surface).
const Color _accessAccent = AppColors.primary;   // cobalt
const Color _sosAccent = Color(0xFFE23B4A);       // danger red
const Color _orientationAccent = Color(0xFF00A87E); // teal
const Color _svcAccent = Color(0xFFEC7E00);       // warning orange

/// Hub page — aggregator for campus services.
class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openSVCProgram(BuildContext context) {
    context.push(AppRoutes.svcDashboard);
  }

  Future<void> _openClubFair(BuildContext context) async {
    if (OrientationConfig.isClosed) {
      context.push(AppRoutes.orientationClosed);
      return;
    }
    context.push(AppRoutes.orientationWeek);
  }

  void _openTutorial(
    BuildContext context,
    AppLocalizations l10n,
    String tutorialId,
  ) {
    final slides = switch (tutorialId) {
      TutorialIds.svcMeal     => TutorialContent.svcMeal(l10n),
      TutorialIds.saltoAccess => TutorialContent.saltoAccess(l10n),
      TutorialIds.referral    => TutorialContent.referral(l10n),
      TutorialIds.profile     => TutorialContent.profile(l10n),
      _                       => <TutorialSlide>[],
    };
    if (slides.isEmpty) return;
    AnalyticsService.instance.trackTutorialBannerTapped(tutorialId: tutorialId);
    // Skip the fade when the system "reduce motion" preference is on —
    // the tutorial still opens, just instantly instead of animated.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        pageBuilder: (ctx, animation, _) => FadeTransition(
          opacity: animation,
          child: TutorialStoryPage(tutorialId: tutorialId, slides: slides),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Scoped to just the 2 fields the avatar renders — an unrelated
    // profile-field change elsewhere no longer rebuilds this app-bar icon.
    final avatarIdentity = ref.watch(
      userProvider.select(
        (s) => (initials: s.valueOrNull?.initials, avatarUrl: s.valueOrNull?.avatarUrl),
      ),
    );
    final unreadCount = ref.watch(unreadCountProvider);
    final l10n = AppLocalizations.of(context)!;
    final bellLabel = unreadCount > 0
        ? '${l10n.notifications_title}, $unreadCount ${l10n.notifications_unread}'
        : l10n.notifications_title;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Hub',
        leadingWidth: 56,
        leading: Semantics(
          button: true,
          label: l10n.profile_title,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: _HubAvatarLeading(
                  initials: avatarIdentity.initials,
                  avatarUrl: avatarIdentity.avatarUrl,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: bellLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.notifications),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: _HubBellAction(unreadCount: unreadCount)),
              ),
            ),
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        final ok =
            await ref.read(svcMealProvider.notifier).loadState(force: true);
        if (!ok && context.mounted) {
          AppToast.showError(context, l10n.common_error);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tutorial banners ──────────────────────────────────────────
            const SizedBox(height: 12),
            _TutorialBannersRow(
              isSvcMember: ref.watch(svcMealProvider.select((s) => s.isMember)),
              onTap: (id) => _openTutorial(context, l10n, id),
            ),
            const SizedBox(height: 28),

            // ── Main Services ─────────────────────────────────────────────
            Text(
              l10n.hub_mainServices,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMainServiceCard(
                    context,
                    title: l10n.bottomNav_access,
                    iconPath: AppIcons.lockOpen,
                    color: _accessAccent.withValues(alpha: 0.12),
                    iconColor: _accessAccent,
                    onTap: () => context.go(AppRoutes.access),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMainServiceCard(
                    context,
                    title: l10n.hub_sos,
                    iconPath: AppIcons.shieldAlert,
                    color: _sosAccent.withValues(alpha: 0.12),
                    iconColor: _sosAccent,
                    onTap: () => context.push(AppRoutes.sosForm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMainServiceCard(
                    context,
                    title: 'Club Fair',
                    iconPath: AppIcons.compass,
                    imageAsset: 'assets/adsl.jpeg',
                    color: _orientationAccent.withValues(alpha: 0.12),
                    iconColor: _orientationAccent,
                    onTap: () => _openClubFair(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── SVC section (members only) ────────────────────────────────
            if (ref.watch(svcMealProvider.select((s) => s.isMember))) ...[
              Text(
                l10n.svc_title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMainServiceCard(
                      context,
                      title: l10n.svc_title,
                      iconPath: AppIcons.utensils,
                      color: _svcAccent.withValues(alpha: 0.12),
                      iconColor: _svcAccent,
                      onTap: () => _openSVCProgram(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // ── Coming Soon ───────────────────────────────────────────────
            Text(
              l10n.hub_comingSoon,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComingSoonCard(
                    context,
                    title: l10n.hub_jobFinder,
                    iconPath: AppIcons.briefcase,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComingSoonCard(
                    context,
                    title: l10n.hub_fintech,
                    iconPath: AppIcons.trendingUp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComingSoonCard(
                    context,
                    title: l10n.hub_courses,
                    iconPath: AppIcons.course,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Classroom ─────────────────────────────────────────────────
            Text(
              l10n.hub_classroom,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComingSoonCard(
                    context,
                    title: l10n.hub_attendanceStudent,
                    iconPath: AppIcons.school,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComingSoonCard(
                    context,
                    title: l10n.hub_attendanceTeacher,
                    iconPath: AppIcons.assignment,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMainServiceCard(
    BuildContext context, {
    required String title,
    required AppIconData iconPath,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    String? badge,
    String? imageAsset,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.trackHubItemTapped(itemName: title);
        onTap();
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: imageAsset != null
                    ? Image.asset(imageAsset, fit: BoxFit.cover)
                    : Center(child: AppIcon(iconPath, size: 36, color: iconColor)),
              ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 28,
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(
    BuildContext context, {
    required String title,
    required AppIconData iconPath,
  }) {
    final theme = Theme.of(context);
    final greyBg = Colors.grey.shade100;
    final greyIcon = Colors.grey.shade400;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: greyBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: AppIcon(iconPath, size: 36, color: greyIcon)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 16,
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Tutorial banners ─────────────────────────────────────────────────────────

/// Small 4:3 landscape banner cards in a single horizontal swipeable row.
class _TutorialBannersRow extends StatelessWidget {
  const _TutorialBannersRow({
    required this.onTap,
    required this.isSvcMember,
  });

  final void Function(String tutorialId) onTap;
  final bool isSvcMember;

  static const _banners = [
    _BannerData(
      tutorialId: TutorialIds.svcMeal,
      imagePath: 'assets/banners/meal.webp',
    ),
    _BannerData(
      tutorialId: TutorialIds.saltoAccess,
      imagePath: 'assets/banners/salto.webp',
    ),
    _BannerData(
      tutorialId: TutorialIds.referral,
      imagePath: 'assets/banners/referral.webp',
    ),
    _BannerData(
      tutorialId: TutorialIds.profile,
      imagePath: 'assets/banners/digitalID.webp',
    ),
  ];

  String _label(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    return switch (id) {
      TutorialIds.svcMeal     => l10n.svc_title,
      TutorialIds.saltoAccess => l10n.bottomNav_access,
      TutorialIds.referral    => l10n.referral_title,
      TutorialIds.profile     => l10n.settings_title,
      _                       => id,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Banner height drives width via 4:3 ratio.
    const bannerHeight = 96.0;
    const bannerWidth = bannerHeight * 4 / 3; // = 128

    final visible = _banners
        .where((b) => b.tutorialId != TutorialIds.svcMeal || isSvcMember)
        .toList();

    return SizedBox(
      height: bannerHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: visible.length,
        itemBuilder: (context, i) {
          final b = visible[i];
          return Padding(
            padding: EdgeInsets.only(right: i < visible.length - 1 ? 10 : 0),
            child: SizedBox(
              width: bannerWidth,
              child: _TutorialBannerCard(
                data: b,
                label: _label(context, b.tutorialId),
                onTap: () => onTap(b.tutorialId),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.tutorialId,
    required this.imagePath,
  });

  final String tutorialId;
  final String imagePath;
}

class _TutorialBannerCard extends StatelessWidget {
  const _TutorialBannerCard({
    required this.data,
    required this.label,
    required this.onTap,
  });

  final _BannerData data;
  final String label;
  final VoidCallback onTap;

  static const _textShadows = <Shadow>[
    Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54),
    Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black45),
  ];

  @override
  Widget build(BuildContext context) {
    // Decode exactly to physical pixel width so the GPU does zero scaling.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (128 * dpr).ceil();

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data.imagePath,
              fit: BoxFit.cover,
              cacheWidth: cacheW,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),

            // Bottom scrim for label legibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Label bottom-left
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  shadows: _textShadows,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar leading ───────────────────────────────────────────────────────────

class _HubAvatarLeading extends StatelessWidget {
  const _HubAvatarLeading({this.initials, this.avatarUrl});
  final String? initials;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedInitials = initials ?? '?';
    final avatarPath = avatarUrl;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarPath != null && avatarPath.isNotEmpty
          ? Image(
              image: getAvatarImageProvider(
                avatarPath,
                cacheWidth: (34 * MediaQuery.of(context).devicePixelRatio).round(),
              ),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initials(initials: resolvedInitials, theme: theme),
            )
          : _Initials(initials: resolvedInitials, theme: theme),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.theme});
  final String initials;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Bell action ──────────────────────────────────────────────────────────────

class _HubBellAction extends StatelessWidget {
  const _HubBellAction({required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLight ? AppColors.textColor : AppColors.textColorDark;

    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: AppIcon(AppIcons.notification, size: 24, color: iconColor)),
          if (unreadCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
