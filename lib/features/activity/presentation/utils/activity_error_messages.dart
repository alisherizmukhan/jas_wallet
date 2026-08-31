import '../../../../l10n/app_localizations.dart';
import '../../domain/activity_api_exception.dart';

String activitySaveUserMessage(ActivityApiException e, AppLocalizations l10n) {
  switch (e.kind) {
    case ActivityErrorKind.network:
      return l10n.profile_errorNetwork;
    case ActivityErrorKind.session:
      return l10n.profile_errorSession;
    case ActivityErrorKind.imageTooLarge:
      return l10n.profile_activityPhotoTooLarge;
    case ActivityErrorKind.imageRead:
      return l10n.profile_activityPhotoRead;
    case ActivityErrorKind.maxPhotos:
      return l10n.profile_activityMaxPhotos;
    case ActivityErrorKind.serverDetail:
      final m = e.message.trim();
      return m.isNotEmpty ? m : l10n.profile_activitySaveFailed;
    case ActivityErrorKind.unknown:
      return l10n.profile_errorGeneric;
  }
}

String activityDeleteUserMessage(ActivityApiException e, AppLocalizations l10n) {
  switch (e.kind) {
    case ActivityErrorKind.network:
      return l10n.profile_errorNetwork;
    case ActivityErrorKind.session:
      return l10n.profile_errorSession;
    case ActivityErrorKind.serverDetail:
      final m = e.message.trim();
      return m.isNotEmpty ? m : l10n.profile_activityDeleteFailed;
    default:
      return l10n.profile_activityDeleteFailed;
  }
}
