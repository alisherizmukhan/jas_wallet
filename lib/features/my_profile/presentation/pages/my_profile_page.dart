import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../settings/presentation/providers/profile_completion_provider.dart';
import '../../../settings/presentation/providers/section_highlight_provider.dart';
import '../../../settings/presentation/widgets/profile_dashboard/section_highlight_border.dart';
import '../../../about_me/presentation/widgets/about_me_section.dart';
import '../../../experience/presentation/widgets/experience_section.dart';
import '../../../skills/presentation/widgets/skills_section.dart';
import '../../../academy/presentation/widgets/academy_section.dart';
import '../../../activity/presentation/widgets/activity_section.dart';

/// Sections that are displayed directly on the MyProfile page.
const _kMyProfileSections = {
  ProfileSection.aboutMe,
  ProfileSection.experience,
  ProfileSection.skills,
  ProfileSection.academy,
  ProfileSection.activity,
};

/// My Profile page — shows user profile with editable resume sections.
class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final _scrollController = ScrollController();

  // Section keys for auto-scroll
  final _aboutMeKey = GlobalKey();
  final _experienceKey = GlobalKey();
  final _skillsKey = GlobalKey();
  final _academyActivityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final active = ref.read(sectionHighlightProvider);
      if (active.isNotEmpty) {
        ref.read(sectionHighlightProvider.notifier).trigger(active);
        _scrollToHighlighted(active);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlighted(Set<ProfileSection> sections) {
    GlobalKey? key;
    if (sections.contains(ProfileSection.aboutMe)) {
      key = _aboutMeKey;
    } else if (sections.contains(ProfileSection.experience)) {
      key = _experienceKey;
    } else if (sections.contains(ProfileSection.skills)) {
      key = _skillsKey;
    } else if (sections.contains(ProfileSection.academy) ||
        sections.contains(ProfileSection.activity)) {
      key = _academyActivityKey;
      if (sections.contains(ProfileSection.activity)) {
        _tabController.animateTo(1);
      } else {
        _tabController.animateTo(0);
      }
    }

    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
    }
  }

  void _handleCompletionTap(
    ProfileSection firstMissing,
    Set<ProfileSection> allMissing,
  ) {
    ref.read(sectionHighlightProvider.notifier).trigger(allMissing);

    if (_kMyProfileSections.contains(firstMissing)) {
      // Section is on this page — scroll to it without navigating
      _scrollToHighlighted({firstMissing});
    } else {
      // Basic profile field — go to EditProfile
      context.push(AppRoutes.editProfile);
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
        title: l10n.profile_title,
        actions: [
          IconButton(
            tooltip: l10n.common_edit,
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: AppIcon(
              AppIcons.edit,
              size: 24,
              color: isLight ? AppColors.iconGrey : AppColors.white,
            ),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          // Scoped to just the fields this page renders (a Dart record, so
          // Riverpod's select() uses structural equality) — an unrelated
          // User field changing elsewhere (email, phone, faculty, ...) no
          // longer rebuilds this whole scrollable page.
          final selected = ref.watch(
            userProvider.select((s) {
              final u = s.valueOrNull;
              if (u == null) return null;
              return (
                level: u.level,
                avatarUrl: u.avatarUrl,
                fullName: u.fullName,
                displayUsername: u.displayUsername,
                bio: u.bio,
              );
            }),
          );
          if (selected == null) return const _MyProfilePlaceholder();
          final user = selected;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),

                // ── Avatar row ─────────────────────────────────────────────
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: getAvatarImageProvider(
                              user.avatarUrl,
                              cacheWidth: (68 * MediaQuery.of(context).devicePixelRatio).round(),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${user.level}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user.displayUsername,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Text(
                    user.bio!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                  ),

                const SizedBox(height: 16),

                // ── Completion card ────────────────────────────────────────
                _ProfileCompletionCard(onTap: _handleCompletionTap),

                const SizedBox(height: 16),

                // ── About Me ───────────────────────────────────────────────
                Padding(
                  key: _aboutMeKey,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SectionHighlightBorder(
                    section: ProfileSection.aboutMe,
                    child: AboutMeSection(
                      isOwnProfile: true,
                      onEditTap: () => context.push(AppRoutes.editAboutMe),
                    ),
                  ),
                ),

                // ── Experience ─────────────────────────────────────────────
                Padding(
                  key: _experienceKey,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SectionHighlightBorder(
                    section: ProfileSection.experience,
                    child: ExperienceSection(
                      userId: null,
                      isOwnProfile: true,
                      onEditTap: () => context.push(AppRoutes.editExperience),
                    ),
                  ),
                ),

                // ── Skills ─────────────────────────────────────────────────
                Padding(
                  key: _skillsKey,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SectionHighlightBorder(
                    section: ProfileSection.skills,
                    child: SkillsSection(
                      userId: null,
                      isOwnProfile: true,
                      onEditTap: () => context.push(AppRoutes.editSkills),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Academy / Activity tabs ─────────────────────────────────
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v < -200 && _tabController.index < _tabController.length - 1) {
                      _tabController.animateTo(_tabController.index + 1);
                    } else if (v > 200 && _tabController.index > 0) {
                      _tabController.animateTo(_tabController.index - 1);
                    }
                  },
                  child: Padding(
                  key: _academyActivityKey,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isLight
                              ? AppColors.fieldBackground
                              : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: isLight ? AppColors.white : AppColors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.all(4),
                          dividerColor: AppColors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                          labelColor: isLight
                              ? AppColors.textColor
                              : AppColors.white,
                          unselectedLabelColor: isLight
                              ? AppColors.grey
                              : AppColors.grey.withValues(alpha: 0.85),
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                          tabs: [
                            Tab(text: l10n.profile_academy),
                            Tab(text: l10n.profile_activity),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTabIndex == 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SectionHighlightBorder(
                            section: ProfileSection.academy,
                            child: AcademySection(
                              userId: null,
                              isOwnProfile: true,
                              onEditTap: () =>
                                  context.push(AppRoutes.editAcademy),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SectionHighlightBorder(
                            section: ProfileSection.activity,
                            child: ActivitySection(
                              maxItems: 2,
                              showHeader: true,
                              showAddButton: true,
                              onEditTap: () =>
                                  context.push(AppRoutes.activity),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Completion card ──────────────────────────────────────────────────────────

class _ProfileCompletionCard extends ConsumerWidget {
  const _ProfileCompletionCard({required this.onTap});

  final void Function(ProfileSection first, Set<ProfileSection> all) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final completionState = ref.watch(profileCompletionProvider);

    if (completionState.isLoading || completionState.isComplete) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        final first = ref
            .read(profileCompletionActionsProvider.notifier)
            .getFirstIncompleteSection();
        if (first == null) return;
        final all = completionState.sectionsFilled.entries
            .where((e) => !e.value)
            .map((e) => e.key)
            .toSet();
        onTap(first, all);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionState.percentage / 100,
                    strokeWidth: 4,
                    backgroundColor: AppColors.primaryLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  Text(
                    '${completionState.percentage}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profile_fillProfile,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profile_completedSteps(
                      completionState.completedCount,
                      completionState.totalCount,
                    ),
                    style: TextStyle(fontSize: 14, color: AppColors.grey),
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

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _MyProfilePlaceholder extends StatelessWidget {
  const _MyProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = isLight ? AppColors.fieldBackground : AppColors.surfaceDark;

    Widget line(double w, {double h = 14}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          ),
          const SizedBox(height: 16),
          line(180, h: 18),
          const SizedBox(height: 8),
          line(120),
          const SizedBox(height: 20),
          line(double.infinity, h: 96),
          const SizedBox(height: 16),
          line(double.infinity, h: 84),
          const SizedBox(height: 12),
          line(double.infinity, h: 84),
        ],
      ),
    );
  }
}
