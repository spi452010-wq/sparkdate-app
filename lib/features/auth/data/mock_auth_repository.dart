import '../../../core/network/api_exception.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// In-memory mock of the Node.js auth API, following the Sprint 1 OTP contract.
/// The valid code is always `123456`. Phone `+910000000000` simulates provider downtime.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({DateTime Function()? clock, this.latency = const Duration(milliseconds: 600)})
      : _now = clock ?? DateTime.now;

  static const validCode = '123456';
  final DateTime Function() _now;
  final Duration latency;

  final _requests = <String, _OtpState>{};
  final _sends = <String, List<DateTime>>{};
  final _wrong = <String, int>{};
  final _lockedUntil = <String, DateTime>{};
  int _seq = 0;

  Future<void> _delay() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    await _delay();
    if (phone == '+910000000000') throw const ApiException(ApiErrorCode.providerUnavailable);
    final now = _now();
    final locked = _lockedUntil[phone];
    if (locked != null && now.isBefore(locked)) throw const ApiException(ApiErrorCode.otpLocked);

    final sends = (_sends[phone] ??= [])
      ..removeWhere((t) => now.difference(t) > const Duration(hours: 1));
    if (sends.isNotEmpty && now.difference(sends.last) < OtpRules.resendCooldown) {
      throw ApiException(ApiErrorCode.otpRateLimited,
          retryAfter: OtpRules.resendCooldown - now.difference(sends.last));
    }
    if (sends.length >= OtpRules.maxResendsPerHour) {
      throw const ApiException(ApiErrorCode.otpRateLimited);
    }
    sends.add(now);
    // A new OTP invalidates any previous one for this phone.
    _requests.removeWhere((_, s) => s.phone == phone);
    final id = 'otp_${++_seq}';
    final expires = now.add(OtpRules.expiry);
    _requests[id] = _OtpState(phone, expires);
    return OtpRequestResult(requestId: id, expiresAt: expires, resendAfter: OtpRules.resendCooldown);
  }

  @override
  Future<AuthSession> verifyOtp({required String requestId, required String phone, required String code}) async {
    await _delay();
    final now = _now();
    final locked = _lockedUntil[phone];
    if (locked != null && now.isBefore(locked)) throw const ApiException(ApiErrorCode.otpLocked);
    if (code.length != OtpRules.length) throw const ApiException(ApiErrorCode.otpInvalid);
    final state = _requests[requestId];
    if (state == null || state.phone != phone) throw const ApiException(ApiErrorCode.otpInvalid);
    if (now.isAfter(state.expiresAt)) {
      _requests.remove(requestId);
      throw const ApiException(ApiErrorCode.otpExpired);
    }
    if (code != validCode) {
      final n = (_wrong[phone] ?? 0) + 1;
      _wrong[phone] = n;
      if (n >= OtpRules.maxWrongAttempts) {
        _lockedUntil[phone] = now.add(OtpRules.lockout);
        _wrong[phone] = 0;
        throw const ApiException(ApiErrorCode.otpLocked);
      }
      throw const ApiException(ApiErrorCode.otpInvalid);
    }
    _requests.remove(requestId); // single use
    _wrong.remove(phone);
    return AuthSession(
      accessToken: 'mock_access_$requestId',
      refreshToken: 'mock_refresh_$requestId',
      userId: 'user_${phone.hashCode.abs()}',
      isProfileComplete: false,
    );
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    await _delay();
    // Stub: real flow will use google_sign_in and POST the idToken to /auth/google.
    return const AuthSession(
      accessToken: 'mock_google_access',
      refreshToken: 'mock_google_refresh',
      userId: 'user_google',
      isProfileComplete: false,
    );
  }
}

class _OtpState {
  _OtpState(this.phone, this.expiresAt);
  final String phone;
  final DateTime expiresAt;
}
