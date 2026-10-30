/// Error codes agreed in the Sprint 1 API contract.
enum ApiErrorCode {
  otpInvalid('OTP_INVALID', 'Incorrect code. Please try again.'),
  otpExpired('OTP_EXPIRED', 'This code has expired. Request a new one.'),
  otpLocked('OTP_LOCKED', 'Too many wrong attempts. Try again in 15 minutes.'),
  otpRateLimited('OTP_RATE_LIMITED', 'Please wait before requesting another code.'),
  providerUnavailable('PROVIDER_UNAVAILABLE', 'WhatsApp is not reachable right now. Please retry.'),
  googleTokenInvalid('GOOGLE_TOKEN_INVALID', 'Google sign-in failed. Please try again.'),
  accountBlocked('ACCOUNT_BLOCKED', 'Your account has been blocked.'),
  unauthorized('UNAUTHORIZED', 'Please log in again.'),
  tokenInvalid('TOKEN_INVALID', 'Please log in again.'),
  refreshInvalid('REFRESH_INVALID', 'Session expired. Please log in again.'),
  refreshReused('REFRESH_REUSED', 'Session expired. Please log in again.'),
  fileRequired('FILE_REQUIRED', 'Please choose a photo.'),
  fileTooLarge('FILE_TOO_LARGE', 'Photo must be under 8 MB.'),
  unsupportedMedia('UNSUPPORTED_MEDIA_TYPE', 'Only JPG, PNG or WEBP photos are allowed.'),
  storageFull('STORAGE_FULL', 'Upload failed. Please try again later.'),
  mediaNotOwned('MEDIA_NOT_OWNED', 'Photo upload failed. Please re-upload.'),
  profileAlreadyCompleted('PROFILE_ALREADY_COMPLETED', 'Your profile is already complete.'),
  validation('VALIDATION_ERROR', 'Please check the details you entered.'),
  unknown('UNKNOWN', 'Something went wrong. Please try again.');

  const ApiErrorCode(this.code, this.message);
  final String code;
  final String message;

  static ApiErrorCode fromCode(String? code) =>
      values.firstWhere((e) => e.code == code, orElse: () => unknown);
}

class ApiException implements Exception {
  const ApiException(this.error, {this.retryAfter});
  final ApiErrorCode error;
  final Duration? retryAfter;

  String get message => error.message;

  @override
  String toString() => 'ApiException(${error.code})';
}
