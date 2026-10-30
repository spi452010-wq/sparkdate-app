import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/auth_models.dart';

class AuthState {
  const AuthState({
    this.phone,
    this.requestId,
    this.expiresAt,
    this.resendIn = 0,
    this.loading = false,
    this.error,
    this.session,
  });

  final String? phone;
  final String? requestId;
  final DateTime? expiresAt;
  final int resendIn;
  final bool loading;
  final ApiException? error;
  final AuthSession? session;

  AuthState copyWith({
    String? phone,
    String? requestId,
    DateTime? expiresAt,
    int? resendIn,
    bool? loading,
    ApiException? error,
    bool clearError = false,
    AuthSession? session,
  }) =>
      AuthState(
        phone: phone ?? this.phone,
        requestId: requestId ?? this.requestId,
        expiresAt: expiresAt ?? this.expiresAt,
        resendIn: resendIn ?? this.resendIn,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        session: session ?? this.session,
      );
}

class AuthController extends GetxController {
  AuthController(this._repo, this._api);
  final AuthRepository _repo;
  final ApiClient _api;
  Timer? _timer;

  final _state = const AuthState().obs;
  AuthState get state => _state.value;
  set state(AuthState v) => _state.value = v;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Returns true when OTP was sent.
  Future<bool> requestOtp(String phone) async {
    if (state.loading) return false;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final r = await _repo.requestOtp(phone);
      state = state.copyWith(
        loading: false,
        phone: phone,
        requestId: r.requestId,
        expiresAt: r.expiresAt,
        resendIn: r.resendAfter.inSeconds,
      );
      _startCooldown();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      return false;
    }
  }

  Future<bool> resend() => requestOtp(state.phone!);

  Future<bool> verify(String code) async {
    if (state.loading || state.requestId == null) return false; // blocks double-tap
    state = state.copyWith(loading: true, clearError: true);
    try {
      final s = await _repo.verifyOtp(requestId: state.requestId!, phone: state.phone!, code: code);
      _onSession(s);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      _onSession(await _repo.signInWithGoogle());
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e);
      return false;
    }
  }

  void _onSession(AuthSession s) {
    _api.accessToken.value = s.accessToken;
    _api.refreshToken.value = s.refreshToken;
    _api.userId.value = s.userId;
    state = state.copyWith(loading: false, session: s);
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.resendIn - 1;
      state = state.copyWith(resendIn: next < 0 ? 0 : next);
      if (next <= 0) t.cancel();
    });
  }
}
