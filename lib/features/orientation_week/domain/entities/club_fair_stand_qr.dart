import 'club_fair_schedule.dart';

/// One club's rotating stand QR for the signed-in representative.
class ClubFairStandQr {
  const ClubFairStandQr({
    required this.club,
    required this.live,
    required this.windowStart,
    required this.windowEnd,
    this.payload,
    this.stepSeconds,
  });

  final ClubFairClubItem club;
  final bool live;
  final String? payload;
  final int? stepSeconds;
  final DateTime windowStart;
  final DateTime windowEnd;

  int get rotationSeconds {
    final step = stepSeconds ?? 18;
    if (step < 5) return 5;
    if (step > 120) return 120;
    return step;
  }
}

class ClubFairStandQrBundle {
  const ClubFairStandQrBundle({required this.isRep, required this.qrs});

  final bool isRep;
  final List<ClubFairStandQr> qrs;
}
