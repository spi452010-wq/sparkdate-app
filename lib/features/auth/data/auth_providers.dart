import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import 'mock_auth_repository.dart';
import 'remote_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockApi) return MockAuthRepository();
  return RemoteAuthRepository(ref.watch(dioProvider));
});
