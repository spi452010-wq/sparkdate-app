import 'package:flutter_test/flutter_test.dart';
import 'package:sparkdate/core/network/api_exception.dart';
import 'package:sparkdate/features/auth/data/mock_auth_repository.dart';

void main() {
  late DateTime now;
  late MockAuthRepository repo;
  const phone = '+919876543210';

  setUp(() {
    now = DateTime(2026, 10, 30, 12);
    repo = MockAuthRepository(clock: () => now, latency: Duration.zero);
  });

  Matcher code(ApiErrorCode c) => throwsA(isA<ApiException>().having((e) => e.error, 'error', c));

  test('valid OTP logs in and is single-use', () async {
    final r = await repo.requestOtp(phone);
    final s = await repo.verifyOtp(requestId: r.requestId, phone: phone, code: '123456');
    expect(s.accessToken, isNotEmpty);
    expect(repo.verifyOtp(requestId: r.requestId, phone: phone, code: '123456'), code(ApiErrorCode.otpInvalid));
  });

  test('wrong code -> OTP_INVALID, 5 wrong -> OTP_LOCKED', () async {
    final r = await repo.requestOtp(phone);
    for (var i = 0; i < 4; i++) {
      await expectLater(repo.verifyOtp(requestId: r.requestId, phone: phone, code: '000000'), code(ApiErrorCode.otpInvalid));
    }
    await expectLater(repo.verifyOtp(requestId: r.requestId, phone: phone, code: '000000'), code(ApiErrorCode.otpLocked));
    await expectLater(repo.verifyOtp(requestId: r.requestId, phone: phone, code: '123456'), code(ApiErrorCode.otpLocked));
  });

  test('expired after 5 minutes -> OTP_EXPIRED', () async {
    final r = await repo.requestOtp(phone);
    now = now.add(const Duration(minutes: 5, seconds: 1));
    expect(repo.verifyOtp(requestId: r.requestId, phone: phone, code: '123456'), code(ApiErrorCode.otpExpired));
  });

  test('resend within 30s -> OTP_RATE_LIMITED; new OTP invalidates old', () async {
    final first = await repo.requestOtp(phone);
    await expectLater(repo.requestOtp(phone), code(ApiErrorCode.otpRateLimited));
    now = now.add(const Duration(seconds: 31));
    final second = await repo.requestOtp(phone);
    await expectLater(repo.verifyOtp(requestId: first.requestId, phone: phone, code: '123456'), code(ApiErrorCode.otpInvalid));
    expect((await repo.verifyOtp(requestId: second.requestId, phone: phone, code: '123456')).userId, isNotEmpty);
  });

  test('max 5 sends per hour', () async {
    for (var i = 0; i < 5; i++) {
      await repo.requestOtp(phone);
      now = now.add(const Duration(seconds: 31));
    }
    expect(repo.requestOtp(phone), code(ApiErrorCode.otpRateLimited));
  });

  test('provider down -> PROVIDER_UNAVAILABLE', () {
    expect(repo.requestOtp('+910000000000'), code(ApiErrorCode.providerUnavailable));
  });

  test('error codes map from backend strings', () {
    expect(ApiErrorCode.fromCode('OTP_LOCKED'), ApiErrorCode.otpLocked);
    expect(ApiErrorCode.fromCode('WHATEVER'), ApiErrorCode.unknown);
  });
}
