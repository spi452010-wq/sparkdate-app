class OtpRequestResult {
  const OtpRequestResult({required this.requestId, required this.expiresAt, required this.resendAfter});
  final String requestId;
  final DateTime expiresAt;
  final Duration resendAfter;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.isProfileComplete,
  });
  final String accessToken;
  final String refreshToken;
  final String userId;
  final bool isProfileComplete;
}

abstract final class OtpRules {
  static const length = 6;
  static const expiry = Duration(minutes: 5);
  static const resendCooldown = Duration(seconds: 30);
  static const maxResendsPerHour = 5;
  static const maxWrongAttempts = 5;
  static const lockout = Duration(minutes: 15);
}
