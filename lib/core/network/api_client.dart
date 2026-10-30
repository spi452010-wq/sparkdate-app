import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

/// Set with --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://...
const useMockApi = bool.fromEnvironment('USE_MOCK', defaultValue: true);
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api/v1');

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(accessTokenProvider);
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
  ));
  return dio;
});

/// In-memory access token (swap for flutter_secure_storage when backend lands).
final accessTokenProvider = StateProvider<String?>((ref) => null);

/// Maps a backend error body `{ "error": { "code": "OTP_INVALID" } }` to [ApiException].
ApiException mapDioError(DioException e) {
  final data = e.response?.data;
  String? code;
  int? retry;
  if (data is Map && data['error'] is Map) {
    final err = data['error'] as Map;
    code = err['code'] as String?;
    final det = err['details'];
    if (det is Map && det['retryAfterSec'] is num) retry = (det['retryAfterSec'] as num).toInt();
  }
  if (code == null && e.type != DioExceptionType.badResponse) {
    return const ApiException(ApiErrorCode.providerUnavailable);
  }
  return ApiException(ApiErrorCode.fromCode(code), retryAfter: retry == null ? null : Duration(seconds: retry));
}
