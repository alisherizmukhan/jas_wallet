import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/club_fair_stand_qr.dart';
import '../providers/orientation_repository_provider.dart';
import '../theme/orientation_brand.dart';
import '../widgets/orientation_app_bar.dart';
import '../widgets/orientation_error_state.dart';

/// Live rotating stand QR for a listed Club Fair representative.
///
/// The payload is issued by the backend (`GET /club-fair/me/club-qr`) and
/// refetched on every rotation step so the HMAC never lives in the client.
class OrientationClubStandQrPage extends ConsumerStatefulWidget {
  const OrientationClubStandQrPage({super.key});

  @override
  ConsumerState<OrientationClubStandQrPage> createState() =>
      _OrientationClubStandQrPageState();
}

class _OrientationClubStandQrPageState extends ConsumerState<OrientationClubStandQrPage> {
  ClubFairStandQrBundle? _bundle;
  bool _loading = true;
  bool _error = false;
  int _lastWindowIndex = -1;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  int _stepSeconds() {
    final live = _bundle?.qrs.where((q) => q.live);
    if (live == null || live.isEmpty) return 18;
    return live.first.rotationSeconds;
  }

  int _windowIndex() {
    final unix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return unix ~/ _stepSeconds();
  }

  void _onTick() {
    if (!mounted) return;
    final index = _windowIndex();
    if (index != _lastWindowIndex) {
      _lastWindowIndex = index;
      _load(silent: true);
      return;
    }
    setState(() {});
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = _bundle == null;
        _error = false;
      });
    }
    try {
      final bundle = await ref.read(orientationRepositoryProvider).getClubStandQrs();
      if (!mounted) return;
      _lastWindowIndex = _windowIndex();
      setState(() {
        _bundle = bundle;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _bundle == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: FeatureStyle.pageBackground,
      appBar: OrientationAppBar(title: l10n.orientation_club_stand_qr_title, showTokens: false),
      body: SafeArea(child: _body(context, l10n)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_loading && _bundle == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error && _bundle == null) {
      return SingleChildScrollView(
        child: OrientationErrorState(onRetry: () { _load(); }),
      );
    }
    final bundle = _bundle;
    if (bundle == null) return const SizedBox.shrink();
    if (!bundle.isRep || bundle.qrs.isEmpty) {
      return FeaturePageBody(
        children: [
          FeatureFadeIn(
            child: FeatureCard(
              padding: const EdgeInsets.all(FeatureStyle.s24),
              child: Text(
                l10n.orientation_club_stand_qr_not_rep,
                textAlign: TextAlign.center,
                style: FeatureStyle.secondary,
              ),
            ),
          ),
        ],
      );
    }

    return FeaturePageBody(
      children: [
        for (var i = 0; i < bundle.qrs.length; i++)
          FeatureFadeIn(
            delay: Duration(milliseconds: 45 * i),
            child: _StandQrCard(qr: bundle.qrs[i]),
          ),
      ],
    );
  }
}

class _StandQrCard extends StatelessWidget {
  const _StandQrCard({required this.qr});

  final ClubFairStandQr qr;

  int get _secondsLeft {
    final step = qr.rotationSeconds;
    final unix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final rem = unix % step;
    return rem == 0 ? step : step - rem;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final live = qr.live && (qr.payload ?? '').isNotEmpty;
    final window = _windowLabel(l10n, locale);
    final left = _secondsLeft;
    final fraction = left / qr.rotationSeconds;

    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s24),
      child: Column(
        children: [
          Text(qr.club.name, textAlign: TextAlign.center, style: FeatureStyle.sectionTitle),
          const SizedBox(height: FeatureStyle.s8),
          _StatusChip(live: live, label: live ? l10n.orientation_club_stand_qr_live : l10n.orientation_club_stand_qr_waiting),
          const SizedBox(height: FeatureStyle.s20),
          Container(
            padding: const EdgeInsets.all(FeatureStyle.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(FeatureStyle.rHero),
              border: FeatureStyle.cardBorder,
            ),
            child: live
                ? QrImageView(
                    data: qr.payload!,
                    size: 220,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    padding: EdgeInsets.zero,
                  )
                : SizedBox(
                    width: 220,
                    height: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(AppIcons.time, size: 36, color: FeatureStyle.stone),
                        const SizedBox(height: FeatureStyle.s12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: FeatureStyle.s12),
                          child: Text(
                            l10n.orientation_club_stand_qr_window(window),
                            textAlign: TextAlign.center,
                            style: FeatureStyle.secondary.copyWith(color: FeatureStyle.stone),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (live) ...[
            const SizedBox(height: FeatureStyle.s20),
            Text(
              l10n.orientation_club_stand_qr_refresh(left),
              style: FeatureStyle.rowValue.copyWith(color: OrientationBrand.accent),
            ),
            const SizedBox(height: FeatureStyle.s8),
            AppProgressBar(
              progress: fraction.clamp(0.0, 1.0),
              height: 7,
              progressColor: OrientationBrand.accent,
            ),
            const SizedBox(height: FeatureStyle.s16),
            Text(
              l10n.orientation_club_stand_qr_body(qr.rotationSeconds),
              textAlign: TextAlign.center,
              style: FeatureStyle.secondary,
            ),
          ] else ...[
            const SizedBox(height: FeatureStyle.s16),
            Text(
              l10n.orientation_club_stand_qr_waiting_body,
              textAlign: TextAlign.center,
              style: FeatureStyle.secondary,
            ),
          ],
        ],
      ),
    );
  }

  String _windowLabel(AppLocalizations l10n, String locale) {
    final start = qr.windowStart.toLocal();
    final end = qr.windowEnd.toLocal();
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (!sameDay) return l10n.orientation_club_stand_qr_all_week;
    final day = DateFormat.MMMd(locale).format(start);
    final from = DateFormat.Hm(locale).format(start);
    final to = DateFormat.Hm(locale).format(end);
    return '$day · $from–$to';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.live, required this.label});

  final bool live;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = live ? OrientationBrand.accentTeal : FeatureStyle.stone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FeatureStyle.chipTint(color),
        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
      ),
      child: Text(
        label,
        style: FeatureStyle.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
