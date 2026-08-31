import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_ui/app_ui.dart';
import 'package:video_compress_kit/video_compress_kit.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/utils/image_picker_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/video_trim_service.dart';
import '../../domain/entities/story.dart';
import '../providers/stories_provider.dart';
import '../pages/story_viewer_page.dart';
import '../pages/story_editor_screen.dart';
import '../utils/story_error_messages.dart';

// ── Card dimensions (4 : 3 landscape announcement card) ───────────────────────
const double _kCardWidth  = 128.0;
const double _kCardHeight = 96.0;
const double _kCardRadius = 12.0;
const double _kCardGap    = 10.0;

/// Announcements bar displayed on the home page.
///
/// Displays stories as landscape 4:3 cards with a full-bleed preview image,
/// a gradient title overlay, and a primary-colour border for unread items.
class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key});

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  static const Duration _maxStoryVideoDuration = Duration(seconds: 20);

  final ValueNotifier<_StoryUploadOverlayState> _uploadState =
      ValueNotifier<_StoryUploadOverlayState>(
        const _StoryUploadOverlayState(
          phase: _StoryUploadPhase.uploading,
          progress: null,
        ),
      );
  final VideoCompressKit _videoCompressKit = const VideoCompressKit();

  @override
  void dispose() {
    _uploadState.dispose();
    super.dispose();
  }

  // ── Story creation ─────────────────────────────────────────────────────────

  Future<void> _createStory() async {
    final organizations =
        ref.read(storyOrganizationsProvider).valueOrNull ?? const [];
    if (organizations.isEmpty || !mounted) return;

    final selectedOrganization = await _pickOrganization(organizations);
    if (selectedOrganization == null || !mounted) return;

    final mediaKind = await _pickStoryMediaKind();
    if (mediaKind == null || !mounted) return;

    final picker = ImagePickerService();
    String? uploadPath;
    int? trimStartMs;
    int? trimEndMs;

    if (mediaKind == _StoryMediaKind.image) {
      final picked = await picker.pickFromGallery(
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (picked.cancelled || !mounted) return;
      if (!picked.isSuccess || picked.path == null) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.stories_publishFailed,
        );
        return;
      }

      final result = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<StoryEditorResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => StoryEditorScreen(
            mediaPath: picked.path!,
            mediaType: StoryMediaType.image,
          ),
        ),
      );
      if (result == null || !mounted) return;
      uploadPath = result.renderedMediaPath;
    } else {
      final picked = await picker.pickVideoFromGallery();
      if (picked.cancelled || !mounted) return;
      if (!picked.isSuccess || picked.path == null) {
        AppToast.showError(
          context,
          AppLocalizations.of(context)!.stories_publishFailed,
        );
        return;
      }

      final result = await Navigator.of(
        context,
        rootNavigator: true,
      ).push<StoryEditorResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => StoryEditorScreen(
            mediaPath: picked.path!,
            mediaType: StoryMediaType.video,
          ),
        ),
      );
      if (result == null || !mounted) return;
      uploadPath = result.renderedMediaPath;
      trimStartMs = result.trimStartMs;
      trimEndMs = result.trimEndMs;
    }

    try {
      await _runUploadWithDialog(() {
        return _publishStoryWithProgress(
          organizationId: selectedOrganization.id,
          sourcePath: uploadPath!,
          mediaKind: mediaKind,
          trimStartMs: trimStartMs,
          trimEndMs: trimEndMs,
        );
      });
      if (!mounted) return;
      AppToast.showSuccess(context, AppLocalizations.of(context)!.common_saved);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = e is ProfileApiException
          ? storyPublishUserMessage(e, l10n)
          : l10n.stories_publishFailed;
      AppToast.showError(context, message);
    }
  }

  Future<void> _publishStoryWithProgress({
    required String organizationId,
    required String sourcePath,
    required _StoryMediaKind mediaKind,
    int? trimStartMs,
    int? trimEndMs,
  }) async {
    var uploadPath = sourcePath;
    if (mediaKind == _StoryMediaKind.video) {
      uploadPath = await _normalizeVideoForUpload(
        sourcePath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
      );
    }

    _setUploadState(
      const _StoryUploadOverlayState(
        phase: _StoryUploadPhase.uploading,
        progress: null,
      ),
    );

    await ref.read(storiesProvider.notifier).createStory(
      organizationId: organizationId,
      filePath: uploadPath,
      onProgress: (progress) {
        _setUploadState(
          _StoryUploadOverlayState(
            phase: _StoryUploadPhase.uploading,
            progress: progress,
          ),
        );
      },
    );
  }

  Future<String> _normalizeVideoForUpload(
    String sourcePath, {
    int? trimStartMs,
    int? trimEndMs,
  }) async {
    _setUploadState(
      const _StoryUploadOverlayState(
        phase: _StoryUploadPhase.processingVideo,
        progress: null,
      ),
    );

    final preparedPath = await _prepareVideoForUploadPath(sourcePath);

    late final MediaInfo info;
    try {
      info = await _videoCompressKit.getMediaInfo(preparedPath);
    } catch (_) {
      throw ProfileApiException(
        'stories_video_read_failed',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }

    // If the user specified a trim range, validate that trimmed duration ≤ limit
    // (not the full video duration).
    final effectiveDurationSecs = (trimStartMs != null && trimEndMs != null)
        ? (trimEndMs - trimStartMs) / 1000.0
        : (info.duration ?? 0).toDouble();

    if (effectiveDurationSecs > _maxStoryVideoDuration.inSeconds) {
      throw ProfileApiException(
        'stories_video_too_long',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }

    // If the user trimmed the video, actually cut the file before uploading.
    if (trimStartMs != null && trimEndMs != null) {
      final trimStart = trimStartMs;
      final trimEnd = trimEndMs;
      // Only trim when the range doesn't cover the full video (allow 500 ms tolerance)
      final fullDurationMs = ((info.duration ?? 0) * 1000).round();
      final coversFull = trimStart <= 500 && (fullDurationMs - trimEnd) <= 500;
      if (!coversFull) {
        final ext = _fileExtension(preparedPath);
        final trimmedPath =
            '${Directory.systemTemp.path}/story_trimmed_${DateTime.now().millisecondsSinceEpoch}${ext.isNotEmpty ? '.$ext' : '.mp4'}';
        try {
          return await VideoTrimService.trimVideo(
            inputPath: preparedPath,
            outputPath: trimmedPath,
            startMs: trimStart,
            endMs: trimEnd,
          );
        } catch (_) {
          // Surface trim failure instead of silently uploading the full clip
          // (which is what the user saw before). A common cause is the app not
          // being rebuilt after the native trim plugin was added — the method
          // channel isn't registered until a fresh native build.
          throw ProfileApiException(
            'stories_trim_failed',
            category: ProfileApiErrorCategory.serverDetail,
          );
        }
      }
    }

    return preparedPath;
  }

  Future<String> _prepareVideoForUploadPath(String path) async {
    final source = File(path);
    final extension = _fileExtension(path);
    final target = File(
      '${Directory.systemTemp.path}/story_video_${DateTime.now().millisecondsSinceEpoch}${extension.isNotEmpty ? '.$extension' : '.mp4'}',
    );
    try {
      await source.copy(target.path);
      return target.path;
    } on FileSystemException {
      throw ProfileApiException(
        'stories_video_read_failed',
        category: ProfileApiErrorCategory.serverDetail,
      );
    }
  }

  void _setUploadState(_StoryUploadOverlayState state) {
    if (!mounted) return;
    _uploadState.value = state;
  }

  Future<void> _runUploadWithDialog(Future<void> Function() action) async {
    if (!mounted) return;
    _setUploadState(
      const _StoryUploadOverlayState(
        phase: _StoryUploadPhase.uploading,
        progress: null,
      ),
    );
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: rootNavigator.context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: ValueListenableBuilder<_StoryUploadOverlayState>(
              valueListenable: _uploadState,
              builder: (context, state, _) {
                final progressValue = state.progress != null && state.progress! > 0
                    ? state.progress!.clamp(0.0, 1.0)
                    : null;
                final percentText = progressValue == null
                    ? null
                    : '${(progressValue * 100).round()}%';
                final title = switch (state.phase) {
                  _StoryUploadPhase.processingVideo => l10n.stories_processingVideo,
                  _StoryUploadPhase.uploading => l10n.stories_uploading,
                };
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    LinearProgressIndicator(value: progressValue),
                    if (percentText != null) ...[
                      SizedBox(height: 12),
                      Text(
                        percentText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    try {
      await action();
    } finally {
      _setUploadState(
        const _StoryUploadOverlayState(
          phase: _StoryUploadPhase.uploading,
          progress: null,
        ),
      );
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _storyCardTitle(UserStory userStory) {
    final trimmed = userStory.userName.trim();
    if (trimmed == 'University Service Management') return 'USM';
    return trimmed;
  }

  String _fileExtension(String value) {
    final normalized = value.trim();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == normalized.length - 1) return '';
    return normalized.substring(dotIndex + 1).toLowerCase();
  }

  Future<_StoryMediaKind?> _pickStoryMediaKind() async {
    final l10n = AppLocalizations.of(context)!;
    return AppBottomSheet.showSelection<_StoryMediaKind>(
      context: context,
      title: l10n.stories_chooseMedia,
      options: [
        AppBottomSheetOption(
          title: l10n.stories_mediaPhoto,
          value: _StoryMediaKind.image,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(AppIcons.image, color: AppColors.primary, size: 20),
            ),
          ),
        ),
        AppBottomSheetOption(
          title: l10n.stories_mediaVideo,
          value: _StoryMediaKind.video,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(AppIcons.video, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Future<StoryPublisherOrganization?> _pickOrganization(
    List<StoryPublisherOrganization> organizations,
  ) async {
    if (organizations.length == 1) return organizations.first;
    final l10n = AppLocalizations.of(context)!;
    return AppBottomSheet.showSelection<StoryPublisherOrganization>(
      context: context,
      title: l10n.stories_publishAs,
      options: organizations
          .map(
            (org) => AppBottomSheetOption(
              title: org.name,
              subtitle: '@${org.slug}',
              value: org,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AppIcon(
                    AppIcons.megaphone,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openStoryViewer(List<UserStory> sortedStories, int userIndex) async {
    if (sortedStories.isEmpty) return;

    // Open the viewer even when offline: cached media renders from disk and
    // uncached items fall back to a placeholder. Blocking here hid stories the
    // user had already loaded.
    final safeIndex = userIndex.clamp(0, sortedStories.length - 1);
    final pageContext = context;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerPage(
            userStories: sortedStories,
            initialUserIndex: safeIndex,
            manageableAuthorIds: ref.read(storyPublisherOrganizationIdsProvider),
            onStoryDeleted: (storyId) async {
              try {
                await ref.read(storiesProvider.notifier).deleteStory(storyId);
              } catch (e) {
                if (!pageContext.mounted) return;
                final l10n = AppLocalizations.of(pageContext)!;
                final message = e is ProfileApiException
                    ? storyDeleteUserMessage(e, l10n)
                    : l10n.stories_deleteFailed;
                AppToast.showError(pageContext, message);
                rethrow;
              }
            },
            onStoriesWatched: () {
              if (mounted) setState(() {});
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final shimmer = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    return SizedBox(
      height: _kCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < 4 ? _kCardGap : 0),
          child: Container(
            width: _kCardWidth,
            height: _kCardHeight,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(_kCardRadius),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storiesAsync = ref.watch(storiesProvider);
    final organizationsAsync = ref.watch(storyOrganizationsProvider);
    final canPublish = ref.watch(storyCanPublishProvider);
    final userStories = ref.watch(userStoriesProvider);
    final showAddCard = canPublish;

    if (storiesAsync.isLoading && userStories.isEmpty && !showAddCard) {
      return _buildLoadingSkeleton(context);
    }

    if (storiesAsync.hasError && userStories.isEmpty && !showAddCard) {
      return SizedBox(
        height: _kCardHeight,
        child: Center(
          child: TextButton(
            onPressed: () {
              ref.read(storiesProvider.notifier).refresh();
              ref.read(storyOrganizationsProvider.notifier).refresh();
            },
            child: Text(l10n.common_retry),
          ),
        ),
      );
    }

    if (userStories.isEmpty && !showAddCard) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _kCardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: userStories.length + (showAddCard ? 1 : 0),
        itemBuilder: (context, index) {
          if (showAddCard && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: _kCardGap),
              child: _AddStoryCard(
                onTap: organizationsAsync.isLoading ? null : _createStory,
              ),
            );
          }

          final storyIndex = showAddCard ? index - 1 : index;
          final userStory = userStories[storyIndex];
          final firstStory = userStory.stories.first;

          return Padding(
            padding: EdgeInsets.only(
              right: storyIndex < userStories.length - 1 ? _kCardGap : 0,
            ),
            child: _AnnouncementCard(
              title: _storyCardTitle(userStory),
              previewImage: firstStory.mediaUrl,
              isVideoPreview: firstStory.mediaType == StoryMediaType.video,
              hasUnwatchedStories: userStory.hasUnviewedStories,
              onTap: () {
                AnalyticsService.instance.trackStoryCardTapped(
                  userId: userStory.userId,
                  userName: userStory.userName,
                );
                _openStoryViewer(userStories, storyIndex);
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _AddStoryCard — 3:4 portrait card for creating a new announcement
// ═══════════════════════════════════════════════════════════════════════════════

class _AddStoryCard extends StatelessWidget {
  const _AddStoryCard({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kCardWidth,
        height: _kCardHeight,
        decoration: BoxDecoration(
          color: isLight
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: AppIcon(AppIcons.addCircle, size: 22, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.stories_addStory,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _AnnouncementCard — 4:3 landscape announcement card (Instagram-style ring)
// ═══════════════════════════════════════════════════════════════════════════════

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.title,
    this.previewImage,
    required this.isVideoPreview,
    required this.hasUnwatchedStories,
    required this.onTap,
  });

  final String title;
  final String? previewImage;
  final bool isVideoPreview;
  final bool hasUnwatchedStories;
  final VoidCallback onTap;

  static const _unseenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
  );
  static const _ringWidth = 2.5;

  @override
  Widget build(BuildContext context) {
    if (hasUnwatchedStories) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: _kCardWidth,
          height: _kCardHeight,
          padding: const EdgeInsets.all(_ringWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kCardRadius + 1),
            gradient: _unseenGradient,
            boxShadow: HomeShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kCardRadius - 1),
            child: _buildCardBody(),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.65,
        child: Container(
          width: _kCardWidth,
          height: _kCardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: HomeShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_kCardRadius - 1),
            child: _buildCardBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF111111)),
        _buildPreview(),
        if (isVideoPreview)
          const Center(
            child: Icon(
              Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 36,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (isVideoPreview) {
      return Container(color: const Color(0xFF1A1A1A));
    }

    final url = previewImage;
    if (url == null || url.isEmpty) return _buildFallback();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        memCacheWidth: 256,
        errorWidget: (ctx, _, _) => _buildFallback(),
      );
    }
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (ctx, err, st) => _buildFallback(),
      );
    }
    return Image.asset(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (ctx, err, st) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.10),
      child: const Center(
        child: AppIcon(AppIcons.logo, size: 40),
      ),
    );
  }
}

// ── Internal types ─────────────────────────────────────────────────────────────

enum _StoryUploadPhase { processingVideo, uploading }

class _StoryUploadOverlayState {
  const _StoryUploadOverlayState({
    required this.phase,
    required this.progress,
  });

  final _StoryUploadPhase phase;
  final double? progress;
}

enum _StoryMediaKind { image, video }
