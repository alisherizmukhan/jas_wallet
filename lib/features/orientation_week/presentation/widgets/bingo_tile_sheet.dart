import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../config/orientation_links.dart';
import '../../domain/entities/bingo_tile.dart';
import '../theme/orientation_brand.dart';

/// What the student chose in the tile sheet.
enum BingoTileAction {
  /// Self-mark this manual tile as done.
  markComplete,

  /// Open the QR scanner to have a supervisor confirm this tile.
  scanQr,

  /// Run the server task behind this square — the same flow as the
  /// Challenges tab (answer sheet, peer/venue scan, referral screen).
  openTask,

  /// The square is a Photo Quest mission — jump to the Photo Quest tab.
  openPhotoQuest,
}

/// Detail sheet for a single Bingo square: what the task is, what it pays,
/// and the action appropriate to how it's verified.
///
/// - Manual tiles show "Mark as Complete".
/// - Supervisor tiles show "Scan QR Code".
/// - Auto tiles show an info notice — they can't be self-marked.
///
/// Resolves the chosen [BingoTileAction], or `null` on dismiss / read-only.
Future<BingoTileAction?> showBingoTileSheet(BuildContext context, BingoTile tile) {
  return AppBottomSheet.show<BingoTileAction>(
    context: context,
    child: _BingoTileSheetContent(tile: tile),
  );
}

class _BingoTileSheetContent extends StatelessWidget {
  const _BingoTileSheetContent({required this.tile});

  final BingoTile tile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tile.title,
          textAlign: TextAlign.center,
          style: FeatureStyle.sectionTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          tile.description,
          textAlign: TextAlign.center,
          style: FeatureStyle.body.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
        ),
        if (tile.rewardTokens > 0) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: OrientationBrand.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token artwork keeps its own colours — never tinted.
                  const AppIcon(AppIcons.tokenAdsl, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+${tile.rewardTokens}',
                    style: FeatureStyle.cardTitle.copyWith(color: OrientationBrand.accent, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // A square carried out somewhere else offers that destination above
        // its completion action, in the order the student does it: open the
        // profile, come back, mark it done. Stays visible once completed —
        // it is still the shortcut to the page it points at.
        if (tile.link != null) ...[
          FeatureCtaButton(accent: OrientationBrand.accent, 
            label: tile.linkLabel ?? l10n.orientation_challenge_open_link,
            icon: orientationLinkIcon(tile.link!),
            style: FeatureCtaStyle.outlined,
            fullWidth: false,
            onTap: () => openOrientationLink(tile.link!),
          ),
          const SizedBox(height: FeatureStyle.s12),
        ],
        _action(context, l10n),
      ],
    );
  }

  Widget _action(BuildContext context, AppLocalizations l10n) {
    if (tile.isCompleted) {
      return _Notice(
        icon: AppIcons.checkCircle,
        color: AppColors.success,
        label: l10n.orientation_bingo_completed_label,
      );
    }

    // Server squares complete through their own task flow, never self-marked:
    // the button hands over to the Challenges interaction or Photo Quest.
    if (tile.isPhotoTask) {
      return Column(
        children: [
          FeatureCtaButton(accent: OrientationBrand.accent, 
            label: l10n.orientation_tab_photo_quest,
            icon: AppIcons.camera,
            fullWidth: false,
            onTap: () => Navigator.of(context).pop(BingoTileAction.openPhotoQuest),
          ),
          const SizedBox(height: FeatureStyle.s8),
          Text(
            l10n.orientation_bingo_photo_hint,
            textAlign: TextAlign.center,
            style: FeatureStyle.caption.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
          ),
        ],
      );
    }
    if (tile.opensTaskFlow) {
      return FeatureCtaButton(accent: OrientationBrand.accent, 
        label: l10n.orientation_bingo_open_task,
        fullWidth: false,
        onTap: () => Navigator.of(context).pop(BingoTileAction.openTask),
      );
    }

    switch (tile.verification) {
      case BingoVerification.auto:
        return Column(
          children: [
            _Notice(
              icon: AppIcons.flash,
              color: AppColors.blue,
              label: l10n.orientation_bingo_auto_title,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.orientation_bingo_auto_hint,
              textAlign: TextAlign.center,
              style: FeatureStyle.caption.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
            ),
          ],
        );
      case BingoVerification.qrScan:
        return Column(
          children: [
            FeatureCtaButton(accent: OrientationBrand.accent, 
              label: l10n.orientation_bingo_scan_qr,
              icon: AppIcons.qrCode,
              // Content-width, so it sits at the same visual weight as the
              // "Completed" / "Tracked automatically" pills this sheet shows
              // in its other states.
              fullWidth: false,
              onTap: tile.isPlayable
                  ? () => Navigator.of(context).pop(BingoTileAction.scanQr)
                  : null,
            ),
            const SizedBox(height: FeatureStyle.s8),
            Text(
              l10n.orientation_bingo_scan_hint,
              textAlign: TextAlign.center,
              style: FeatureStyle.caption.copyWith(color: FeatureStyle.mute, fontWeight: FontWeight.w400),
            ),
          ],
        );
      case BingoVerification.manual:
        return FeatureCtaButton(accent: OrientationBrand.accent, 
          label: l10n.orientation_bingo_mark_complete,
          fullWidth: false,
          onTap: tile.isPlayable
              ? () => Navigator.of(context).pop(BingoTileAction.markComplete)
              : null,
        );
    }
  }
}

/// A status pill for a state the student can't act on ("Completed",
/// "Tracked automatically").
///
/// Deliberately hugs its label rather than filling the sheet: a full-width
/// block reads like a button and invites a tap, which is exactly wrong for a
/// read-only state. Sized to content, it reads as a badge.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.label});

  final AppIconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.s16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(FeatureStyle.rPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 18, color: color),
            const SizedBox(width: FeatureStyle.s8),
            Flexible(
              child: Text(
                label,
                style: FeatureStyle.cardTitle.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
