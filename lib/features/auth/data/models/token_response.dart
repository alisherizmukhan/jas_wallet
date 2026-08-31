/// Response from auth endpoints (login, verify-otp, refresh).
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
}
