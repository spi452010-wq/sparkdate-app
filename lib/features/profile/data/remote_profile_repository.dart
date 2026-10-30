import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Real client for docs/api/AUTH_PROFILE_MEDIA.md.
/// Photos go as multipart/form-data (field `file`) to the API, which stores them on its disk
/// and returns only `{ key }`. Profile reads return 15-min signed URLs: never persist them,
/// cache images by [photoCacheKey] instead.
class RemoteProfileRepository implements ProfileRepository {
  RemoteProfileRepository(this._dio);
  final Dio _dio;

  @override
  Future<String> uploadPhoto(String path) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: path.split('/').last),
      });
      final r = await _dio.post<Map<String, dynamic>>('/media/photos', data: form);
      return r.data!['key'] as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<ProfileView> saveProfile(ProfileDraft d) async {
    final key = await uploadPhoto(d.photoPath!);
    try {
      final r = await _dio.put<Map<String, dynamic>>('/profile/me', data: completeProfileBody(d, [key]));
      return ProfileView.fromJson(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<ProfileView> getMe() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/profile/me');
      return ProfileView.fromJson(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<ProfileView> updateProfile(Map<String, dynamic> changes) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>('/profile/me', data: changes);
      return ProfileView.fromJson(r.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<String> submitSelfie(String path) async {
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(path, filename: path.split('/').last)});
      final up = await _dio.post<Map<String, dynamic>>('/media/selfie', data: form);
      final r = await _dio.post<Map<String, dynamic>>('/profile/me/verification', data: {'selfieKey': up.data!['key']});
      return r.data!['status'] as String;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

/// Stable image cache key: signed URLs change on every read, the photo key does not.
String photoCacheKey(String photoKey) => 'photo:$photoKey';
