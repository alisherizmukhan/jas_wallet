/// Achievement tier unlocked by reaching a referral milestone.
enum ReferralTier {
  none,
  explorer,
  communityBuilder,
  campusInfluencer,
  ambassador,
}

/// Definition of a referral achievement level.
class ReferralLevel {
  const ReferralLevel({
    required this.tier,
    required this.name,
    required this.requiredInvites,
  });

  final ReferralTier tier;
  final String name;
  final int requiredInvites;

  /// All levels in ascending order of required invites.
  static const List<ReferralLevel> all = [
    ReferralLevel(
      tier: ReferralTier.explorer,
      name: 'Explorer',
      requiredInvites: 1,
    ),
    ReferralLevel(
      tier: ReferralTier.communityBuilder,
      name: 'Community Builder',
      requiredInvites: 5,
    ),
    ReferralLevel(
      tier: ReferralTier.campusInfluencer,
      name: 'Campus Influencer',
      requiredInvites: 10,
    ),
    ReferralLevel(
      tier: ReferralTier.ambassador,
      name: 'Ambassador',
      requiredInvites: 25,
    ),
  ];

  bool isUnlocked(int inviteCount) => inviteCount >= requiredInvites;
}
