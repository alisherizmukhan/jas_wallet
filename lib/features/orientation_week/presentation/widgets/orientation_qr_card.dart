import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/orientation_identity.dart';
import '../theme/orientation_brand.dart';

/// The student's own Orientation code, drawn.
///
/// `mobile_scanner` only *reads* codes, so this is the one place in the app
/// that renders one. Deliberately plain black-on-white with a generous quiet
/// zone rather than tinted to the brand accent: a cobalt QR on a tinted card
/// is measurably harder for a phone camera to lock onto across a table, and
/// this code exists to be scanned by a stranger in a crowded hall.
class OrientationQrCard extends StatelessWidget {
  const OrientationQrCard({super.key, required this.identity, this.size = 220});

  final OrientationIdentity identity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      padding: const EdgeInsets.all(FeatureStyle.s24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(FeatureStyle.s16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(FeatureStyle.rHero),
              border: FeatureStyle.cardBorder,
            ),
            child: QrImageView(
              data: identity.encode(),
              size: size,
              backgroundColor: Colors.white,
              // Medium recovers from a thumb over a corner without inflating
              // the module count the way High would on a payload this size.
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: FeatureStyle.s20),
          Text(
            identity.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FeatureStyle.sectionTitle,
          ),
          const SizedBox(height: FeatureStyle.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Chip(label: identity.school.code, accent: OrientationBrand.accent),
              const SizedBox(width: FeatureStyle.s8),
              _Chip(label: identity.studentId, accent: FeatureStyle.stone),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FeatureStyle.chipTint(accent),
        borderRadius: BorderRadius.circular(FeatureStyle.rPill),
      ),
      child: Text(
        label,
        style: FeatureStyle.caption.copyWith(color: accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}
