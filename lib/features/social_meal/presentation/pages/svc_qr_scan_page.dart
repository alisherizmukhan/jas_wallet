import 'dart:ui';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../data/models/social_meal_redeem_response.dart';
import '../../providers/meal_schedule_provider.dart';
import '../../providers/svc_meal_provider.dart';

// ─── Scan state machine ───────────────────────────────────────────────────────

enum _ScanState {
  scanning,   // Camera live, viewfinder shown, waiting for QR
  processing, // QR detected, API call in flight — camera paused
  success,    // API returned 200 — success overlay shown
  error,      // API or network error — error modal shown
}

// ─── Page ─────────────────────────────────────────────────────────────────────

/// Cafeteria meal-redemption QR scanner. The camera, viewfinder, zoom and
/// close chrome all come from the shared [AppQrScanner] in `app_ui`; this
/// page only owns the redemption flow — post the scanned code to the backend
/// and layer the processing / success / error result over the scanner.
class SVCQrScanPage extends ConsumerStatefulWidget {
  const SVCQrScanPage({super.key});

  @override
  ConsumerState<SVCQrScanPage> createState() => _SVCQrScanPageState();
}

class _SVCQrScanPageState extends ConsumerState<SVCQrScanPage> with TickerProviderStateMixin {
  // ── Success overlay animations ─────────────────────────────────────────────
  late final AnimationController _successCtrl;
  late final Animation<double> _bgFade;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _iconScale;

  // ── Error modal animations ─────────────────────────────────────────────────
  late final AnimationController _errorCtrl;
  late final Animation<double> _errorScale;
  late final Animation<double> _errorFade;

  // ── Page state ─────────────────────────────────────────────────────────────
  _ScanState _state = _ScanState.scanning;
  SocialMealRedeemResponse? _successData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackSvcQrOpened();

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _bgFade = CurvedAnimation(parent: _successCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _cardSlide = Tween<double>(begin: 72, end: 0).animate(
      CurvedAnimation(parent: _successCtrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic)),
    );
    _cardFade = CurvedAnimation(parent: _successCtrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _iconScale = CurvedAnimation(parent: _successCtrl, curve: const Interval(0.1, 1.0, curve: Curves.elasticOut));

    _errorCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _errorScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _errorCtrl, curve: Curves.easeOutCubic),
    );
    _errorFade = CurvedAnimation(parent: _errorCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  // ── QR detection ──────────────────────────────────────────────────────────

  Future<void> _processQr(String qrValue) async {
    if (!mounted) return;
    setState(() => _state = _ScanState.processing);

    AnalyticsService.instance.trackSvcScanAttempted();
    final result = await ref.read(svcMealProvider.notifier).redeemMeal(qrValue);
    if (!mounted) return;

    if (result.isSuccess) {
      AnalyticsService.instance.trackSvcScanSuccess();
      HapticFeedback.heavyImpact();
      _refreshMealStateAfterRedeem();
      setState(() {
        _state = _ScanState.success;
        _successData = result.response;
      });
      _successCtrl.forward();
    } else {
      AnalyticsService.instance.trackSvcScanFailed(reason: result.errorMessage ?? 'unknown');
      HapticFeedback.vibrate();
      setState(() {
        _state = _ScanState.error;
        _errorMessage = result.errorMessage;
      });
      _errorCtrl.forward();
    }
  }

  /// After a successful redeem the server marks the slot as received, so we
  /// drop every cached meal view to force a fresh sync.
  void _refreshMealStateAfterRedeem() {
    ref.invalidate(mealScheduleProvider);
    ref.invalidate(mealStreakProvider);
    ref.invalidate(mealMonthScheduleProvider);
    ref.invalidate(mealScheduleForDateProvider);
    ref.invalidate(mealHistoryProvider);
    ref.invalidate(mealHistoryPagedProvider);
  }

  void _resumeScanning() {
    _errorCtrl.reset();
    setState(() {
      _state = _ScanState.scanning;
      _errorMessage = null;
      _successData = null;
    });
  }

  void _close() => context.go(AppRoutes.svcDashboard);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = ref.watch(userProvider).valueOrNull;

    return AppQrScanner(
      active: _state == _ScanState.scanning,
      showViewfinder: _state != _ScanState.success,
      title: l10n.svc_scanToReceive,
      instruction: _state == _ScanState.processing ? l10n.svc_processing : l10n.svc_pointCameraAtQr,
      cameraErrorText: l10n.svc_cameraPermissionDenied,
      openSettingsText: l10n.svc_openSettings,
      onClose: _close,
      onDetect: _processQr,
      overlay: switch (_state) {
        _ScanState.scanning => null,
        _ScanState.processing => const _ProcessingOverlay(),
        _ScanState.success => _SuccessOverlay(
            successData: _successData,
            studentName: student?.fullName,
            studentAvatarUrl: student?.avatarUrl,
            studentId: student?.studentId,
            bgFade: _bgFade,
            cardSlide: _cardSlide,
            cardFade: _cardFade,
            iconScale: _iconScale,
            onDone: _close,
          ),
        _ScanState.error => _ErrorModal(
            message: _errorMessage ?? l10n.svc_qrScanGenericError,
            errorScale: _errorScale,
            errorFade: _errorFade,
            onScanAgain: _resumeScanning,
            onClose: _close,
            l10n: l10n,
          ),
      },
    );
  }
}

// ─── Processing overlay ────────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: SizedBox(
          width: 52,
          height: 52,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        ),
      ),
    );
  }
}

// ─── Success overlay ──────────────────────────────────────────────────────────
//
// This confirmation screen is read by the canteen cashier, not the student —
// so unlike the rest of the app, its copy is fixed Russian text and does NOT
// go through AppLocalizations. It must read the same regardless of whatever
// language the student's own device is set to.

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({
    required this.successData,
    required this.studentName,
    required this.studentAvatarUrl,
    required this.studentId,
    required this.bgFade,
    required this.cardSlide,
    required this.cardFade,
    required this.iconScale,
    required this.onDone,
  });

  final SocialMealRedeemResponse? successData;
  final String? studentName;
  final String? studentAvatarUrl;
  final String? studentId;
  final Animation<double> bgFade;
  final Animation<double> cardSlide;
  final Animation<double> cardFade;
  final Animation<double> iconScale;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bgFade,
      builder: (context, child) => Container(
        color: Colors.black.withValues(alpha: 0.80 * bgFade.value),
        child: child,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: iconScale,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.28), width: 1.5),
                  ),
                  child: const AppIcon(AppIcons.check, color: AppColors.green, size: 52),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: cardFade,
                child: const Text(
                  'Прием пищи получен!',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: cardFade,
                child: Text(
                  'Ваш прием пищи успешно получен. Приятного аппетита!',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: cardSlide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, cardSlide.value),
                  child: FadeTransition(opacity: cardFade, child: child),
                ),
                child: _RedemptionCard(
                  data: successData,
                  studentName: studentName,
                  studentAvatarUrl: studentAvatarUrl,
                  studentId: studentId,
                  onDone: onDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Redemption detail card ────────────────────────────────────────────────────

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({
    required this.data,
    required this.studentName,
    required this.studentAvatarUrl,
    required this.studentId,
    required this.onDone,
  });

  final SocialMealRedeemResponse? data;
  final String? studentName;
  final String? studentAvatarUrl;
  final String? studentId;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final hasAvatarUrl = studentAvatarUrl != null && studentAvatarUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16172A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.18), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CashierBanner(),
          const SizedBox(height: 16),
          if (studentName != null && studentName!.isNotEmpty) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.green.withValues(alpha: 0.16),
                  backgroundImage: hasAvatarUrl ? NetworkImage(studentAvatarUrl!) : null,
                  child: hasAvatarUrl
                      ? null
                      : Text(
                          _initials(studentName!),
                          style: const TextStyle(color: AppColors.green, fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName!,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (studentId != null && studentId!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          studentId!,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.48), fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const _Divider(),
            const SizedBox(height: 15),
          ],
          if (data != null) ...[
            _DetailRow(label: 'Визит', value: '#${data!.visitNumber}', valueColor: AppColors.green),
            const SizedBox(height: 11),
            const _Divider(),
            const SizedBox(height: 11),
            _DetailRow(label: 'Дата', value: _formatDate(data!.mealDate)),
            const SizedBox(height: 11),
            _DetailRow(label: 'Время', value: _formatTime(data!.scannedAt)),
            const SizedBox(height: 11),
            _DetailRow(label: 'Осталось сегодня', value: '${data!.remainingSlotsToday}'),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Готово', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─── Error modal ──────────────────────────────────────────────────────────────

class _ErrorModal extends StatelessWidget {
  const _ErrorModal({
    required this.message,
    required this.errorScale,
    required this.errorFade,
    required this.onScanAgain,
    required this.onClose,
    required this.l10n,
  });

  final String message;
  final Animation<double> errorScale;
  final Animation<double> errorFade;
  final VoidCallback onScanAgain;
  final VoidCallback onClose;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ScaleTransition(
            scale: errorScale,
            child: FadeTransition(
              opacity: errorFade,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.16), shape: BoxShape.circle),
                          child: const AppIcon(AppIcons.qrCode, color: AppColors.red, size: 30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.svc_invalidQr,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 13.5, height: 1.45),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onScanAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(l10n.svc_scanAgain, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onClose,
                          child: Text(
                            l10n.common_close,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

/// Instruction banner telling the student to hand their screen to the
/// cashier. Deliberately styled in orange rather than the card's green —
/// green here means "confirmed data", orange means "action needed" — so
/// the instruction reads as a distinct call-out, not another stat row.
class _CashierBanner extends StatelessWidget {
  const _CashierBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(AppIcons.visibility, color: AppColors.orange, size: 17),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Покажите кассиру',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.15),
                ),
                SizedBox(height: 2),
                Text(
                  'Эта страница подтверждает получение питания',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.48), fontSize: 14.5)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.08));
  }
}
