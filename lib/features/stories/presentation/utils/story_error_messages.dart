import '../../../../core/errors/profile_api_exception.dart';
import '../../../../core/localization/profile_errors.dart';
import '../../../../l10n/app_localizations.dart';

String storyPublishUserMessage(ProfileApiException e, AppLocalizations l10n) {
  if (e.category == ProfileApiErrorCategory.serverDetail) {
    switch (e.message.trim()) {
      case 'stories_publish_forbidden':
        return l10n.stories_publishForbidden;
      case 'stories_video_read_failed':
        return l10n.stories_videoReadFailed;
      case 'stories_video_process_failed':
        return l10n.stories_videoProcessFailed;
      case 'stories_media_unsupported':
        return l10n.stories_mediaUnsupported;
      case 'stories_media_too_large':
        return l10n.stories_mediaTooLarge;
      case 'stories_video_too_long':
        return l10n.stories_videoTooLong;
      case 'stories_trim_failed':
        return l10n.stories_trimFailed;
    }
  }

  return profileApiUserMessage(
    e,
    l10n,
    serverFallback: l10n.stories_publishFailed,
  );
}

String storyDeleteUserMessage(ProfileApiException e, AppLocalizations l10n) {
  if (e.category == ProfileApiErrorCategory.serverDetail) {
    switch (e.message.trim()) {
      case 'stories_delete_forbidden':
        return l10n.stories_deleteForbidden;
      case 'stories_not_found':
        return l10n.stories_notFound;
    }
  }

  return profileApiUserMessage(
    e,
    l10n,
    serverFallback: l10n.stories_deleteFailed,
  );
}
