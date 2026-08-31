import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/onboarding_content.dart' as onboarding_data;
import '../../data/onboarding_content_helper.dart';

/// Onboarding page with 7 pages.
/// Design: Clean UI with 9:16 aspect ratio images, dot indicators, and bottom controls.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<onboarding_data.OnboardingPage> _pages = [];

  int get _totalPages => _pages.length;

  // Tracks whether the last page transition was initiated by a button tap
  // (true) or by a finger swipe on the PageView (false).
  bool _isButtonNav = false;

  // Timestamp when the current step became visible — used to compute
  // per-step time spent.
  DateTime _stepEnteredAt = DateTime.now();

  // Prevents firing onboarding_abandoned in dispose after a normal exit.
  bool _onboardingFinished = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackOnboardingStarted();
    _stepEnteredAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = OnboardingContentHelper.getPages(context);
  }

  @override
  void dispose() {
    if (!_onboardingFinished) {
      AnalyticsService.instance.trackOnboardingAbandoned(
        atStep: _currentPage + 1,
        totalSteps: _totalPages,
      );
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      AnalyticsService.instance
          .trackOnboardingNextClicked(fromStep: _currentPage + 1);
      _isButtonNav = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      AnalyticsService.instance
          .trackOnboardingBackClicked(fromStep: _currentPage + 1);
      _isButtonNav = true;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onboardingFinished = true; // back to language selection — not abandoned
      ref.read(authProvider.notifier).resetToFirstLaunch();
      context.go(AppRoutes.languageSelection);
    }
  }

  void _skip() {
    _onboardingFinished = true;
    AnalyticsService.instance.trackOnboardingSkipped(atStep: _currentPage);
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    _onboardingFinished = true;
    AnalyticsService.instance.trackOnboardingCompleted();
    await ref.read(authProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _totalPages - 1;
    final onboardingPages = _pages;

    // Dot indicator builder
    Widget buildDotIndicator() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppAppBar(
        showBackButton: true,
        onBackPressed: _previousPage,
        showDivider: false,
        backgroundColor: Colors.transparent,
        actions: [
          Theme(
             data: theme.copyWith(iconTheme: const IconThemeData(color: Colors.white)),
             child: TextButton(
              onPressed: _skip,
              child: Text(
                l10n.common_skip,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image Layer
          PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (page) {
              // Capture navigation method before resetting the flag.
              final wasButtonNav = _isButtonNav;
              _isButtonNav = false;

              // Compute time spent on the step the user just left.
              final now = DateTime.now();
              final timeSpentMs =
                  now.difference(_stepEnteredAt).inMilliseconds;
              _stepEnteredAt = now;

              // Track swipe if the user dragged the PageView directly.
              if (!wasButtonNav) {
                AnalyticsService.instance.trackOnboardingSwiped(
                  fromStep: _currentPage + 1,
                  toStep: page + 1,
                  direction: page > _currentPage ? 'forward' : 'backward',
                );
              }

              setState(() => _currentPage = page);

              // Existing event — kept intact, now enriched with time data.
              AnalyticsService.instance.trackOnboardingStepCompleted(
                step: page + 1,
                totalSteps: _totalPages,
                timeSpentMs: timeSpentMs,
              );

              // New richer event with navigation method.
              AnalyticsService.instance.trackOnboardingStepViewed(
                step: page + 1,
                totalSteps: _totalPages,
                navigationMethod: wasButtonNav ? 'button' : 'swipe',
                timeSpentOnPreviousMs: timeSpentMs,
              );
            },
            itemBuilder: (context, index) {
              final pageData = onboardingPages[index];
              return Image.asset(
                pageData.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(index, theme),
              );
            },
          ),

          // Top Gradient Overlay (Deepened for better text visibility)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 500, // Extended height
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9), // Darker at top
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper spacer to push text down from the very edge
                  const SizedBox(height: 16),

                  // Title (Top, refined typography)
                  Text(
                    onboardingPages[_currentPage].title,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800, // Bolder
                      color: AppColors.white,
                      height: 1.1,
                      fontSize: 30,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description (Top, refined typography)
                  Text(
                    onboardingPages[_currentPage].description,
                    textAlign: TextAlign.start,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.95),
                      height: 1.4,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Indicators (Moved to bottom above button)
                  Center(child: buildDotIndicator()),

                  const SizedBox(height: 24),

                  // Action Button (Bottom)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? l10n.common_start : l10n.common_next,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isLastPage) ...[
                            const SizedBox(width: 8),
                            const AppIcon(
                              AppIcons.arrowForward,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(int index, ThemeData theme) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: AppIcon(
          _getPageIcon(index),
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  AppIconData _getPageIcon(int index) {
    switch (index) {
      case 0: return AppIcons.location;
      case 1: return AppIcons.users;
      case 2: return AppIcons.school;
      case 3: return AppIcons.trending;
      case 4: return AppIcons.gift;
      case 5: return AppIcons.security;
      case 6: return AppIcons.sparkles;
      default: return AppIcons.star;
    }
  }
}
