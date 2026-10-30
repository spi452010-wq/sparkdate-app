import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// Real implementation against the Node.js API (endpoints per draft contract).
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._dio);
  final Dio _dio;

  @override
  Future<OtpRequestResult> requestOtp(String phone) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/auth/otp/request', data: {'phone': phone});
      final d = r.data!;
      // API returns { expiresInSec, resendAfterSec }; the phone identifies the OTP.
      return OtpRequestResult(
        requestId: phone,
        expiresAt: DateTime.now().add(Duration(seconds: (d['expiresInSec'] as num).toInt())),
        resendAfter: Duration(seconds: (d['resendAfterSec'] as num).toInt()),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<AuthSession> verifyOtp({required String requestId, required String phone, required String code}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/auth/otp/verify',
          data: {'phone': phone, 'code': code});
      return _session(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() {
    throw UnimplementedError('Google sign-in will be wired with google_sign_in in a later sprint.');
  }

  AuthSession _session(Map<String, dynamic> d) => AuthSession(
        accessToken: d['accessToken'] as String,
        refreshToken: d['refreshToken'] as String,
        userId: (d['user'] as Map)['id'] as String,
        isProfileComplete: (d['user'] as Map)['profileCompleted'] as bool? ?? false,
      );
}
