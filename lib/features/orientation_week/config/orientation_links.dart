import 'package:app_ui/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The off-app destinations Orientation Week sends students to.
///
/// Kept in one place because each of these is referenced from more than one
/// screen — the ADSL profile is both a partner credit on the Overview and a
/// follow task on Challenges, and the prize number appears as readable copy
/// *and* as a `wa.me` link. Two spellings of the same handle or number is the
/// kind of drift nobody notices until a student taps the wrong one.
abstract class OrientationLinks {
  /// Blockchain & Fintech Lab — the same profile the referral contest links
  /// to, so a student who followed it there is already done here.
  static const String labsInstagram = 'https://instagram.com/blockchain.fintech.lab';
  static const String labsHandle = '@blockchain.fintech.lab';

  /// ADSL — Orientation Week's partner for the week.
  static const String adslInstagram = 'https://www.instagram.com/adsl_nu/';
  static const String adslHandle = '@adsl_nu';

  /// Who a student contacts to collect a redeemed prize.
  ///
  /// [prizeWhatsAppNumber] is the display form; [prizeWhatsApp] is the same
  /// number as `wa.me` wants it — digits only, no `+` and no separators.
  static const String prizeWhatsAppNumber = '+7 707 840 31 16';
  static const String prizeWhatsApp = 'https://wa.me/77078403116';

  /// In-app / technical questions — BFL Telegram post we reply under.
  static const String techSupportTelegram = 'https://t.me/bflabnu/17';
}

/// The mark of whichever app [url] opens, so a button that leaves for
/// Instagram is stamped with Instagram rather than a generic chain link.
/// Falls back to the chain link for anything unrecognised.
AppIconData orientationLinkIcon(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.contains('instagram.com')) return AppIcons.instagram;
  if (host.contains('wa.me') || host.contains('whatsapp.com')) return AppIcons.whatsapp;
  if (host.contains('t.me') || host.contains('telegram')) return AppIcons.telegram;
  return AppIcons.link;
}

/// Opens [url] in the external app that handles it (Instagram, WhatsApp, the
/// browser).
///
/// Silent when nothing can handle it: these are all supplementary — a student
/// who can't open Instagram has lost a shortcut, not the task, and an error
/// toast fired from a row tap would be more noise than help.
Future<void> openOrientationLink(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
