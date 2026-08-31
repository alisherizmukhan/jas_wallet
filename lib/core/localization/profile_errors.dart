import '../../l10n/app_localizations.dart';
import '../errors/profile_api_exception.dart';

String profileApiUserMessage(
  ProfileApiException e,
  AppLocalizations l10n, {
  required String serverFallback,
}) {
  switch (e.category) {
    case ProfileApiErrorCategory.network:
      return l10n.profile_errorNetwork;
    case ProfileApiErrorCategory.session:
      return l10n.profile_errorSession;
    case ProfileApiErrorCategory.serverDetail:
      final m = e.message.trim();
      return m.isNotEmpty ? m : serverFallback;
    case ProfileApiErrorCategory.unknown:
      return l10n.profile_errorGeneric;
  }
}
