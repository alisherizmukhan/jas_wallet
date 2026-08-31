import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../domain/entities/bingo_board.dart';
import '../../domain/entities/bingo_tile.dart';
import '../providers/orientation_bingo_provider.dart';
import '../widgets/bingo_board_grid.dart';
import '../widgets/bingo_progress_card.dart';
import '../widgets/bingo_tile_sheet.dart';
import '../widgets/club_fair_scan_flow.dart';
import '../widgets/orientation_error_state.dart';
import '../widgets/orientation_skeletons.dart';
import '../widgets/orientation_app_bar.dart';
import '../theme/orientation_brand.dart';

/// Club Fair bingo — 4×4 of random quest clubs. Squares close when that
/// club's rotating QR is scanned (Home or the button under the grid).
class NetworkingBingoPage extends ConsumerStatefulWidget {
  const NetworkingBingoPage({super.key});

  @override
  ConsumerState<NetworkingBingoPage> createState() => _NetworkingBingoPageState();
}

class _NetworkingBingoPageState extends ConsumerState<NetworkingBingoPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackOrientationBingoOpened();
  }

  Future<void> _onTileTap(BingoTile tile) async {
    final action = await showBingoTileSheet(context, tile);
    if (!mounted) return;
    if (action == BingoTileAction.scanQr) {
      await openClubFairScan(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(orientationBingoProvider);

    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(
        title: l10n.orientation_tab_bingo,
        isShellRoot: true,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(orientationBingoProvider.notifier).load(),
          child: _buildBody(context, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, BingoState state) {
    if (state.isLoading && state.board == null) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(padding: EdgeInsets.only(top: 20), child: OrientationBingoSkeleton()),
      );
    }
    if (state.error != null && state.board == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: OrientationErrorState(onRetry: () => ref.read(orientationBingoProvider.notifier).load()),
      );
    }

    final board = state.board;
    if (board == null) return const SizedBox.shrink();

    const stagger = Duration(milliseconds: 45);

    return FeaturePageBody(
      children: [
        FeatureFadeIn(
          child: BingoBoardGrid(
            board: board,
            processingTileId: state.processingTileId,
            onTileTap: _onTileTap,
          ),
        ),
        FeatureFadeIn(
          delay: stagger,
          child: FeatureCtaButton(
            accent: OrientationBrand.accent,
            label: l10n.orientation_club_scan_cta,
            icon: AppIcons.qrCode,
            onTap: () => openClubFairScan(context, ref),
          ),
        ),
        FeatureFadeIn(
          delay: stagger * 2,
          child: BingoProgressCard(
            progress: board.progress,
            bonusTokens: BingoBoard.grandBonusTokens,
          ),
        ),
      ],
    );
  }
}
