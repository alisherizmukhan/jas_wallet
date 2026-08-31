class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.referralCount,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  final String name;
  final int referralCount;
  final bool isCurrentUser;
  final String? avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // BACKEND RESPONSE SHAPE:
  // { "name": string, "referral_count": int, "is_current_user": bool, "avatar_url": string? }
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] as String? ?? '',
      referralCount: json['referral_count'] as int? ?? json['referralCount'] as int? ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? json['isCurrentUser'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
    );
  }
}
