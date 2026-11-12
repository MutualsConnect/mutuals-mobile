import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

/// Motivos para reportar a alguien (`ReportReason`).
enum ReportReason {
  spam('SPAM', 'Spam'),
  harassment('HARASSMENT', 'Acoso'),
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Contenido inapropiado'),
  impersonation('IMPERSONATION', 'Se hace pasar por otra persona'),
  other('OTHER', 'Otro motivo');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}

/// Edición del perfil propio, bloqueos y reportes.
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  /// Actualiza tu nombre y tu biografía.
  Future<void> updateProfile({
    required String displayName,
    required String bio,
  }) => _guard(
    () => _dio.patch<void>(
      '/users/me',
      data: {'displayName': displayName.trim(), 'bio': bio.trim()},
    ),
  );

  Future<void> block(int userId) =>
      _guard(() => _dio.post<void>('/users/$userId/block'));

  Future<void> unblock(int userId) =>
      _guard(() => _dio.delete<void>('/users/$userId/block'));

  Future<void> report(int userId, ReportReason reason, {String? description}) =>
      _guard(
        () => _dio.post<void>(
          '/reports',
          data: {
            'reportedUserId': userId,
            'reason': reason.code,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          },
        ),
      );

  Future<void> _guard(Future<Response<void>> Function() call) async {
    try {
      await call();
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);
