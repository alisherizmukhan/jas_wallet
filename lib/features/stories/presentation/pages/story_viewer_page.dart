import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/story.dart';
import '../../data/story_service.dart';

/// System UI style for stories - dark theme like Instagram
const _storiesSystemStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Color(0xFF171717),
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Story viewer page using flutter_story_presenter for Instagram-like experience.
/// 
/// Controls:
/// - Tap RIGHT: Next story of current user
/// - Tap LEFT: Previous story (restart if > 2 seconds played)
/// - Swipe LEFT: Next user's stories
/// - Swipe RIGHT: Previous user's stories
/// - Hold: Pause story
/// - Release: Resume story
/// - Swipe DOWN: Exit stories
class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.userStories,
    required this.initialUserIndex,
    this.onStoriesWatched,
    this.manageableAuthorIds = const <String>{},
    this.onStoryDeleted,
  });

  final List<UserStory> userStories;
  final int initialUserIndex;
  final VoidCallback? onStoriesWatched;
  final Set<String> manageableAuthorIds;
  final Future<void> Function(String storyId)? onStoryDeleted;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  late PageController _pageController;
  int _currentUserIndex = 0;
  bool _isNavigating = false;
  bool _isPopping = false;
  final StoryService _storyService = StoryService.instance;
  
  // Stores forced starting indices for specific users
  // Used when navigating backwards to show the last slide
  final Map<int, int> _forcedInitialIndices = {};

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _pageController = PageController(initialPage: widget.initialUserIndex);

    final initialUser = widget.userStories[widget.initialUserIndex];
    AnalyticsService.instance.trackStorySetViewed(
      authorId: initialUser.userId,
      storyCount: initialUser.stories.length,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _currentUserIndex = index;
      _isNavigating = false;
    });
  }

  void _goToNextUser() {
    if (!mounted || _isNavigating || _isPopping) return;

    if (!_pageController.hasClients) {
      _exitStories();
      return;
    }

    if (_currentUserIndex < widget.userStories.length - 1) {
      AnalyticsService.instance.trackStoryUserNavigated(direction: 'next');
      // When going forward, ensure we rely on default behavior (first unwatched)
      // rather than any forced index from previous interactions
      _forcedInitialIndices.remove(_currentUserIndex + 1);

      _isNavigating = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _exitStories();
    }
  }

  void _goToPreviousUser() {
    if (!mounted || _isNavigating || _isPopping) return;

    if (!_pageController.hasClients) {
      _exitStories();
      return;
    }

    if (_currentUserIndex > 0) {
      AnalyticsService.instance.trackStoryUserNavigated(direction: 'previous');
      // When going back, we want to land on the LAST slide of the previous user
      final prevIndex = _currentUserIndex - 1;
      final storiesCount = widget.userStories[prevIndex].stories.length;

      // Store the forced index
      _forcedInitialIndices[prevIndex] = storiesCount > 0 ? storiesCount - 1 : 0;

      // Force rebuild of widgets to pick up the new index if they are cached
      setState(() {});

      _isNavigating = true;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _exitStories();
    }
  }

  void _exitStories() {
    if (!mounted || _isPopping) return;
    _isPopping = true;
    widget.onStoriesWatched?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Called when user finishes all stories of a user
  void _onUserStoriesCompleted(String userId, List<Story> stories) {
    for (final s in stories) {
      _storyService.markViewed(s.id);
    }
    AnalyticsService.instance.trackStorySetCompleted(authorId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _storiesSystemStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFF171717),
        // Instagram layout: status bar (visible) → content (fills the rest) →
        // nav bar (visible). No action button, so the content is full-height —
        // the editor's content area matches (its Share button just floats over
        // the bottom of the same-sized content).
        body: SafeArea(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 300) {
                _goToPreviousUser();
              } else if (velocity < -300) {
                _goToNextUser();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.userStories.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                // Determine initial start index:
                // 1. If explicitly forced (coming from next user → show last slide)
                // 2. Default: first unwatched slide
                final userStory = widget.userStories[index];
                final int initialStoryIndex = _forcedInitialIndices[index] ??
                    _storyService.getFirstUnviewedIndex(
                      userStory.userId,
                      userStory.stories,
                    );

                return _UserStoryView(
                  key: ValueKey('user_story_$index'),
                  userStory: userStory,
                  initialStoryIndex: initialStoryIndex,
                  onNextUser: _goToNextUser,
                  onPreviousUser: _goToPreviousUser,
                  onExit: _exitStories,
                  onStoriesCompleted: _onUserStoriesCompleted,
                  isActive: index == _currentUserIndex,
                  isLast: index == widget.userStories.length - 1,
                  isFirst: index == 0,
                  manageableAuthorIds: widget.manageableAuthorIds,
                  onStoryDeleted: widget.onStoryDeleted,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual user's story view with FlutterStoryPresenter
class _UserStoryView extends StatefulWidget {
  const _UserStoryView({
    super.key,
    required this.userStory,
    required this.initialStoryIndex,
    required this.onNextUser,
    required this.onPreviousUser,
    required this.onExit,
    required this.onStoriesCompleted,
    required this.isActive,
    required this.isLast,
    required this.isFirst,
    this.manageableAuthorIds = const <String>{},
    this.onStoryDeleted,
  });

  final UserStory userStory;
  final int initialStoryIndex;
  final VoidCallback onNextUser;
  final VoidCallback onPreviousUser;
  final VoidCallback onExit;
  final void Function(String userId, List<Story> stories) onStoriesCompleted;
  final bool isActive;
  final bool isLast;
  final bool isFirst;
  final Set<String> manageableAuthorIds;
  final Future<void> Function(String storyId)? onStoryDeleted;

  @override
  State<_UserStoryView> createState() => _UserStoryViewState();
}

class _UserStoryViewState extends State<_UserStoryView> {
  FlutterStoryController? _storyController;
  int _currentStoryIndex = 0;
  bool _isDisposed = false;
  final StoryService _storyService = StoryService.instance;

  // Counter incremented when we need to force-recreate FlutterStoryPresenter
  // (e.g. when navigating back to a previous user's last story).
  int _presenterKey = 0;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    if (widget.isActive) {
      _storyController = FlutterStoryController();
    }
  }

  @override
  void didUpdateWidget(_UserStoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _storyController = FlutterStoryController();
    } else if (!widget.isActive && oldWidget.isActive) {
      // FlutterStoryPresenter disposes the provided controller when its subtree
      // unmounts, so drop our reference as soon as this page becomes inactive.
      _storyController = null;
    }

    // If the forced initial index changed (e.g. parent navigating back to this
    // user's last story), recreate the presenter with the correct initialIndex
    // rather than calling jumpTo — jumpTo leaves a stale jumpIndex on the
    // controller that re-fires on every subsequent notifyListeners call.
    if (widget.initialStoryIndex != oldWidget.initialStoryIndex &&
        widget.initialStoryIndex != _currentStoryIndex) {
      setState(() {
        _currentStoryIndex = widget.initialStoryIndex;
        _presenterKey++;
        if (widget.isActive) {
          // New controller so the recreated presenter starts clean.
          _storyController = FlutterStoryController();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _storyController = null;
    super.dispose();
  }

  bool get _canInteract => mounted && !_isDisposed && _storyController != null;

  /// Mark current story as watched and check if all stories are now watched
  void _markCurrentStoryWatched() {
    // Mark individual story as viewed
    if (_currentStoryIndex < widget.userStory.stories.length) {
      _storyService.markViewed(
        widget.userStory.stories[_currentStoryIndex].id,
      );
    }
    
    // Check if all stories are now watched (user reached the last story)
    if (_currentStoryIndex == widget.userStory.stories.length - 1) {
      widget.onStoriesCompleted(
        widget.userStory.userId,
        widget.userStory.stories,
      );
    }
  }

  /// Convert Story entities to StoryItem for flutter_story_presenter
  List<StoryItem> _convertToStoryItems() {
    return widget.userStory.stories.map((story) {
      final source = story.isAsset
          ? StoryItemSource.asset
          : (story.mediaUrl.startsWith('http://') ||
                    story.mediaUrl.startsWith('https://')
                ? StoryItemSource.network
                : StoryItemSource.file);

      if (story.mediaType == StoryMediaType.video) {
        return StoryItem(
          storyItemType: StoryItemType.video,
          storyItemSource: source,
          url: story.mediaUrl,
          duration: const Duration(seconds: 15),
          thumbnail: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.common_loading,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          errorWidget: Center(
            child: Container(
              color: const Color(0xFF171717),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(
                    AppIcons.error,
                    color: Colors.white70,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.stories_videoLoadFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          videoConfig: StoryViewVideoConfig(
            // contain → preserve the original aspect ratio (no stretch/crop),
            // matching the editor's contain preview.
            fit: BoxFit.contain,
            // Download the video via Dart HTTP (flutter_cache_manager) before
            // playing. This bypasses ExoPlayer's stricter network requirements
            // on Android, which fail on some CDN configurations that AVPlayer
            // on iOS handles without issue.
            cacheVideo: true,
          ),
        );
      } else {
        return StoryItem(
          storyItemType: StoryItemType.image,
          storyItemSource: source,
          url: story.mediaUrl,
          duration: const Duration(seconds: 15),
          thumbnail: const Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
              strokeWidth: 2,
            ),
          ),
          imageConfig: StoryViewImageConfig(
            fit: BoxFit.contain,
            height: double.infinity,
            width: double.infinity,
            progressIndicatorBuilder: (context, url, progress) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        );
      }
    }).toList();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Handle left tap:
  /// - First story → go to previous user.
  /// - Any other story → return true so the package calls _playPrevious(),
  ///   which decrements the story index and triggers onStoryChanged.
  ///   (Avoids jumpTo whose stale jumpIndex re-fires on every subsequent
  ///   notifyListeners call from the controller.)
  Future<bool> _handleLeftTap() async {
    if (!_canInteract) return false;

    if (_currentStoryIndex == 0) {
      _safeCallback(widget.onPreviousUser);
      return false;
    }

    // Let the package's own _playPrevious() handle navigation.
    return true;
  }

  /// Handle right tap - next story or next user
  Future<bool> _handleRightTap() async {
    if (!_canInteract) return false;
    
    final hasMultipleStories = widget.userStory.stories.length > 1;
    final isLastStory = _currentStoryIndex >= widget.userStory.stories.length - 1;
    
    if (hasMultipleStories && !isLastStory) {
      // Not last story - go to next story
      return true;
    } else {
      // Last story - go to next user
      _safeCallback(widget.onNextUser);
      return false;
    }
  }

  void _safeCallback(VoidCallback callback) {
    if (!_canInteract) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        callback();
      }
    });
  }

  void _onStoryChanged(int index) {
    if (!_canInteract) return;
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        // Mark the previous story as watched when moving to next
        _markCurrentStoryWatched();

        setState(() {
          _currentStoryIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not active, show dark placeholder to prevent multiple video decoders
    if (!widget.isActive || _storyController == null) {
      return const SizedBox.expand(
        child: ColoredBox(color: Color(0xFF171717)),
      );
    }
    
    final storyItems = _convertToStoryItems();
    final currentStory = widget.userStory.stories.isNotEmpty && 
                         _currentStoryIndex < widget.userStory.stories.length
        ? widget.userStory.stories[_currentStoryIndex]
        : widget.userStory.stories.isNotEmpty 
            ? widget.userStory.stories.first 
            : null;

    return Container(
      color: const Color(0xFF171717),
      child: FlutterStoryPresenter(
        key: ValueKey('story_presenter_${widget.userStory.userId}_$_presenterKey'),
        flutterStoryController: _storyController!,
        items: storyItems,
        initialIndex: _currentStoryIndex,
        restartOnCompleted: false,
        // Progress bar config — pure white fill so elapsed time is clearly
        // visible, over a translucent-white track for the remaining time.
        storyViewIndicatorConfig: StoryViewIndicatorConfig(
          height: 3,
          activeColor: Colors.white,
          backgroundCompletedColor: Colors.white,
          backgroundDisabledColor: Colors.white.withValues(alpha: 0.3),
          horizontalGap: 4,
          borderRadius: 2,
          // Let the headerWidget start from y=0 so its gradient covers the
          // progress bars (which are at margin.top=14, no SafeArea).
          enableTopSafeArea: false,
        ),
        // Header with avatar, username, time, and close button
        headerWidget: _buildHeader(currentStory),
        footerWidget: const SizedBox.shrink(),
        onStoryChanged: _onStoryChanged,
        // Tap controls
        onLeftTap: _handleLeftTap,
        onRightTap: _handleRightTap,
        // When going back from first story
        onPreviousCompleted: () async {
          if (!_canInteract) return;
          _safeCallback(widget.onPreviousUser);
        },
        // When all stories completed
        onCompleted: () async {
          if (!_canInteract) return;
          // Mark all stories as watched when completed
          widget.onStoriesCompleted(
            widget.userStory.userId,
            widget.userStory.stories,
          );
          _safeCallback(widget.onNextUser);
        },
        // Swipe down to exit
        onSlideDown: (details) {
          if (!_canInteract) return;
          if (details.delta.dy > 20) {
            widget.onExit();
          }
        },
      ),
    );
  }

  /// Header widget with username, time ago, and close button.
  ///
  /// The content box already sits below the status bar (outer SafeArea), and
  /// the package renders this with enableTopSafeArea=false so the Container
  /// starts at the box top (y=0) — its gradient covers the progress bars
  /// (at margin.top=14) even over bright white video content. The row content
  /// is padded down to clear the progress bars.
  Widget _buildHeader(Story? currentStory) {
    final isManageable = widget.manageableAuthorIds.contains(widget.userStory.userId);
    return SizedBox(
      width: double.infinity,
      child: Container(
        // Gradient starts from the very top of the screen (y=0) and fades to
        // transparent below the header, darkening the progress-bar area and the
        // username/close-button row regardless of how bright the video is.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCC000000), // 80 % — very legible even on white video
              Color(0x88000000), // 53 %
              Color(0x00000000), // transparent
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(
          top: 28,
          left: 12,
          right: 12,
          bottom: 20,
        ),
        child: Row(
          children: [
            // Username and time-ago — takes all remaining space and ellipsises.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.userStory.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ),
                  if (currentStory != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _getTimeAgo(currentStory.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.65),
                          fontSize: 13,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Guaranteed gap so the name can never touch the trailing icons.
            const SizedBox(width: 10),
            // Delete button (own stories only)
            if (isManageable && currentStory != null) ...[
              _headerIconButton(
                AppIcons.delete,
                semanticLabel: AppLocalizations.of(context)!.common_delete,
                onTap: () => _confirmDeleteStory(currentStory),
              ),
              const SizedBox(width: 8),
            ],
            // Close button
            _headerIconButton(
              AppIcons.close,
              semanticLabel: AppLocalizations.of(context)!.common_close,
              onTap: widget.onExit,
            ),
          ],
        ),
      ),
    );
  }

  /// A circle-background icon button used in the story header.
  Widget _headerIconButton(
    AppIconData icon, {
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: AppIcon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteStory(Story story) async {
    final l10n = AppLocalizations.of(context)!;
    _storyController?.pause();
    final confirmed = await AppPremiumDialog.show(
      context: context,
      icon: AppIcons.delete,
      iconColor: const Color(0xFFFF3B30),
      title: l10n.stories_deleteTitle,
      description: l10n.stories_deleteMessage,
      confirmText: l10n.common_delete,
      cancelText: l10n.common_cancel,
      isDestructive: true,
    );
    if (confirmed && mounted) {
      try {
        await widget.onStoryDeleted?.call(story.id);
        if (!mounted) return;
        // Close viewer after deletion to avoid stale in-memory story snapshots.
        widget.onExit();
      } catch (_) {
        if (mounted) {
          _storyController?.play();
        }
      }
    } else {
      _storyController?.play();
    }
  }
}
