import 'referral_level.dart';

/// Core referral domain model.
class ReferralModel {
  const ReferralModel({
    required this.referralCode,
    required this.invitedFriendsCount,
  });

  final String referralCode;
  final int invitedFriendsCount;

  // ── Computed level state ────────────────────────────────────────────────────

  ReferralLevel? get currentLevel {
    final unlocked =
        ReferralLevel.all.where((l) => l.isUnlocked(invitedFriendsCount)).toList();
    return unlocked.isEmpty ? null : unlocked.last;
  }

  ReferralLevel? get nextLevel {
    return ReferralLevel.all.cast<ReferralLevel?>().firstWhere(
      (l) => !l!.isUnlocked(invitedFriendsCount),
      orElse: () => null,
    );
  }

  /// Progress fraction [0.0, 1.0] toward the next level.
  double get progressToNextLevel {
    final next = nextLevel;
    if (next == null) return 1.0;
    final from = currentLevel?.requiredInvites ?? 0;
    final to = next.requiredInvites;
    if (to <= from) return 1.0;
    return (invitedFriendsCount - from) / (to - from);
  }

  int get invitesUntilNextLevel => nextLevel == null
      ? 0
      : nextLevel!.requiredInvites - invitedFriendsCount;

  List<ReferralLevel> get unlockedLevels =>
      ReferralLevel.all.where((l) => l.isUnlocked(invitedFriendsCount)).toList();

  bool get isMaxLevel => nextLevel == null;

  // ── Deep link ───────────────────────────────────────────────────────────────

  /// Deep link URI for this referral code.
  ///
  /// DEEP LINK FORMAT: jaswallet://referral/{code}
  ///
  /// BACKEND INTEGRATION:
  ///   Register this URI scheme in AndroidManifest.xml (intent-filter) and
  ///   Info.plist (CFBundleURLTypes). The backend should parse the referral code
  ///   from this URI on first app launch and attribute the invite to the referrer.
  ///   See docs/backend/referral_and_share_backend_requirements.md for the full
  ///   deep link specification.
  Uri get deepLinkUri => Uri(
        scheme: 'jaswallet',
        host: 'referral',
        pathSegments: [referralCode],
      );

  // ── Serialization ───────────────────────────────────────────────────────────

  ReferralModel copyWith({
    String? referralCode,
    int? invitedFriendsCount,
  }) {
    return ReferralModel(
      referralCode: referralCode ?? this.referralCode,
      invitedFriendsCount: invitedFriendsCount ?? this.invitedFriendsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'referralCode': referralCode,
        'invitedFriendsCount': invitedFriendsCount,
      };

  // BACKEND RESPONSE SHAPE:
  // { "referral_code": string, "invited_friends_count": int }
  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      referralCode: json['referral_code'] as String? ?? json['referralCode'] as String? ?? '',
      invitedFriendsCount: json['invited_friends_count'] as int? ?? json['invitedFriendsCount'] as int? ?? 0,
    );
  }
}
