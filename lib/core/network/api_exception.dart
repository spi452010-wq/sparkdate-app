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
  eventFull('EVENT_FULL', 'This event is full.'),
  alreadyBooked('ALREADY_BOOKED', 'You have already booked this event.'),
  verificationRequired('VERIFICATION_REQUIRED', 'Complete selfie verification to continue.'),
  bookingExpired('BOOKING_EXPIRED', 'Your seat hold expired. Please book again.'),
  purchaseCancelled('PURCHASE_CANCELLED', 'Payment was cancelled.'),
  paymentFailed('PAYMENT_FAILED', 'Payment could not be completed.'),
  billingUnavailable('BILLING_UNAVAILABLE', 'Google Play Billing is not available on this device.'),
  chatPassRequired('CHAT_PASS_REQUIRED', 'Get a Chat Pass to keep chatting.'),
  refundNotEligible('REFUND_NOT_ELIGIBLE', 'This booking is not eligible for a refund.'),
  // Sprint 2 (docs/api/SPRINT2_API.md)
  profileIncomplete('PROFILE_INCOMPLETE', 'Complete your profile first.'),
  notFound('NOT_FOUND', 'Not found.'),
  eventNotFound('EVENT_NOT_FOUND', 'This event is no longer available.'),
  eventNotBookable('EVENT_NOT_BOOKABLE', 'This event is not open for booking.'),
  bookingNotFound('BOOKING_NOT_FOUND', 'Booking not found.'),
  bookingNotCancellable('BOOKING_NOT_CANCELLABLE', 'Only unpaid bookings can be cancelled.'),
  refundAlreadyRequested('REFUND_ALREADY_REQUESTED', 'You have already requested a refund.'),
  refundRejected('REFUND_REJECTED', 'Your refund request was rejected.'),
  purchaseInvalid('PURCHASE_INVALID', 'We could not verify this purchase.'),
  productMismatch('PRODUCT_MISMATCH', 'We could not verify this purchase.'),
  bookingNotPending('BOOKING_NOT_PENDING', 'This booking is no longer waiting for payment. Refreshing its status…'),
  purchaseAlreadyUsed('PURCHASE_ALREADY_USED', 'This purchase was already used.'),
  eventFullRefunded('EVENT_FULL_REFUNDED', 'Your seat hold expired and the event filled up. Your payment is being refunded.'),
  playUnavailable('PLAY_UNAVAILABLE', 'Google Play is unavailable. Please try again shortly.'),
  idempotencyKeyRequired('IDEMPOTENCY_KEY_REQUIRED', 'Something went wrong. Please try again.'),
  idempotencyInProgress('IDEMPOTENCY_IN_PROGRESS', 'Still processing your previous request…'),
  idempotencyKeyReused('IDEMPOTENCY_KEY_REUSED', 'Something went wrong. Please try again.'),
  verificationNotAllowed('VERIFICATION_NOT_ALLOWED', 'Verification is already pending or approved.'),
  paymentPending('PAYMENT_PENDING', 'Payment is pending. We will confirm as soon as Google Play does.'),
  network('NETWORK', 'No connection. Please try again.'),
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

  /// Safe to retry the same action with the same Idempotency-Key.
  bool get retryable => switch (error) {
        ApiErrorCode.network ||
        ApiErrorCode.playUnavailable ||
        ApiErrorCode.idempotencyInProgress ||
        ApiErrorCode.providerUnavailable ||
        ApiErrorCode.unknown => true,
        _ => false,
      };

  @override
  String toString() => 'ApiException(${error.code})';
}
