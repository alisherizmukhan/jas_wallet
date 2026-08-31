import 'package:flutter/material.dart';

import '../../domain/entities/orientation_challenge.dart';
import '../theme/orientation_brand.dart';

/// The accent a challenge carries, keyed off *how it is completed* rather than
/// off its content. Four kinds of work, four colours from the kit — a student
/// learns "pink means scan someone" once and it holds across the list.
Color challengeAccent(ChallengeKind kind) => switch (kind) {
      // Not accentPink (gold): this accent is also used as the action-label
      // pill's *text* colour in `challenge_card.dart`, and gold text fails
      // contrast on the pill's own soft-tint background. `accent` (maroon)
      // reads clearly as text and, as the "meet someone" task, is a fitting
      // home for the feature's single brand-emphasis colour.
      ChallengeKind.qrScan => OrientationBrand.accent,
      ChallengeKind.text || ChallengeKind.name => OrientationBrand.accentCobalt,
      ChallengeKind.handle => OrientationBrand.accentOrange,
      ChallengeKind.telegramBot => OrientationBrand.accentCobalt,
      ChallengeKind.link || ChallengeKind.referral => OrientationBrand.accentTeal,
      ChallengeKind.photo => OrientationBrand.accentPink,
    };

/// The verb on the row's button, which is the clearest signal of what tapping
/// it will actually do.
String challengeActionLabel(OrientationChallenge challenge) => switch (challenge.kind) {
      ChallengeKind.qrScan => 'Scan',
      ChallengeKind.text || ChallengeKind.name || ChallengeKind.handle => 'Answer',
      ChallengeKind.telegramBot => 'Telegram',
      ChallengeKind.link => 'Open',
      ChallengeKind.referral => 'Invite',
      ChallengeKind.photo => 'Photo',
    };
