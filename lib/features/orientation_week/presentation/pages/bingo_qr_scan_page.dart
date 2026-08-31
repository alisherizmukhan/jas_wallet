import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

/// Supervisor-confirmation QR scanner for Bingo tiles.
///
/// A thin wrapper over the shared [AppQrScanner]: the student points the
/// camera at the QR code a supervisor is holding, and the first detected
/// code pops the page with its value. A real deployment would validate the
/// code against the tile; the mock only needs proof that a scan happened.
///
/// Pushed with [Navigator.push]; resolves the scanned string, or `null` if
/// the student backs out.
class BingoQrScanPage extends StatelessWidget {
  const BingoQrScanPage({super.key, required this.tileTitle});

  final String tileTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppQrScanner(
      title: tileTitle,
      instruction: l10n.orientation_bingo_scan_instruction,
      cameraErrorText: l10n.svc_cameraPermissionDenied,
      openSettingsText: l10n.svc_openSettings,
      onClose: () => Navigator.of(context).maybePop(),
      onDetect: (code) => Navigator.of(context).pop(code),
    );
  }
}
