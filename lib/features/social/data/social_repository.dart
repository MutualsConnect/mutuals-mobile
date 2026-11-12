import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/network/providers.dart';
import 'models/social_models.dart';

class SocialRepository {
  SocialRepository(this._dio);

  final Dio _dio;

  /// Busca usuarios por nombre o usuario (mínimo 2 caracteres).
  Future<PageResponse<UserSummary>> search(String query, {int page = 0}) async {
    final data = await _get('/users/search', {'q': query.trim(), 'page': page});
    return PageResponse.fromJson(data, UserSummary.fromJson);
  }

  Future<PublicProfile> profile(int userId) async =>
      PublicProfile.fromJson(await _get('/users/$userId'));

  Future<List<MutualCard>> mutuals() async {
    final response = await _guard(() => _dio.get<List<dynamic>>('/mutuals'));
    return response!
        .map((e) => MutualCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FollowResult> follow(int userId) async {
    final data = await _guard(
      () => _dio.post<Map<String, dynamic>>('/users/$userId/follow'),
    );
    return FollowResult.fromJson(data!);
  }

  /// Si hay una racha activa el servidor responde 409; hay que repetir con
  /// [confirmStreakLoss] en `true` tras confirmar con la persona.
  Future<void> unfollow(int userId, {bool confirmStreakLoss = false}) => _guard(
    () => _dio.delete<void>(
      '/users/$userId/follow',
      queryParameters: {'confirmStreakLoss': confirmStreakLoss},
    ),
  );

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final data = await _guard(
      () => _dio.get<Map<String, dynamic>>(path, queryParameters: query),
    );
    return data!;
  }

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(dioProvider)),
);

final mutualsProvider = FutureProvider.autoDispose<List<MutualCard>>(
  (ref) => ref.watch(socialRepositoryProvider).mutuals(),
);

final profileProvider = FutureProvider.autoDispose.family<PublicProfile, int>(
  (ref, id) => ref.watch(socialRepositoryProvider).profile(id),
);

final searchProvider = FutureProvider.autoDispose
    .family<PageResponse<UserSummary>, String>(
      (ref, query) => ref.watch(socialRepositoryProvider).search(query),
    );
