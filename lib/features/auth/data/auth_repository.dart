import 'auth_models.dart';

abstract interface class AuthRepository {
  /// Sends an OTP to [phone] (E.164, e.g. +919876543210) over WhatsApp.
  Future<OtpRequestResult> requestOtp(String phone);
  Future<AuthSession> verifyOtp({required String requestId, required String phone, required String code});
  Future<AuthSession> signInWithGoogle();
}
