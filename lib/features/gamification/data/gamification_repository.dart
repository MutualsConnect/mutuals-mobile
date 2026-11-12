import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'models/gamification_models.dart';

class GamificationRepository {
  GamificationRepository(this._dio);

  final Dio _dio;

  Future<List<Achievement>> achievements() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/achievements'));
    return data!
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvatarItem>> avatarItems() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/avatar-items'));
    return data!
        .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AvatarItem> purchaseAvatarItem(int itemId) async =>
      AvatarItem.fromJson(
        (await _guard(
          () =>
              _dio.post<Map<String, dynamic>>('/avatar-items/$itemId/purchase'),
        ))!,
      );

  /// Equipa el ítem; reemplaza al que ya tengas puesto en la misma capa.
  Future<AvatarItem> equipAvatarItem(int itemId) async => AvatarItem.fromJson(
    (await _guard(
      () => _dio.put<Map<String, dynamic>>('/users/me/avatar/$itemId'),
    ))!,
  );

  Future<List<Challenge>> challenges() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/challenges'));
    return data!
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Challenge> challenge(int id) async => Challenge.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/challenges/$id')))!,
  );

  /// Envía tu parte del desafío: texto y/o una foto (ruta de un archivo local).
  Future<Challenge> submitChallenge(
    int id, {
    String? content,
    String? photoPath,
  }) async {
    final form = FormData.fromMap({
      if (content != null && content.isNotEmpty) 'content': content,
      if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
    });
    return Challenge.fromJson(
      (await _guard(
        () => _dio.post<Map<String, dynamic>>(
          '/challenges/$id/submissions',
          data: form,
        ),
      ))!,
    );
  }

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(ref.watch(dioProvider)),
);

final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>(
  (ref) => ref.watch(gamificationRepositoryProvider).achievements(),
);

final avatarItemsProvider = FutureProvider.autoDispose<List<AvatarItem>>(
  (ref) => ref.watch(gamificationRepositoryProvider).avatarItems(),
);

final challengesProvider = FutureProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(gamificationRepositoryProvider).challenges(),
);

final challengeProvider = FutureProvider.autoDispose.family<Challenge, int>(
  (ref, id) => ref.watch(gamificationRepositoryProvider).challenge(id),
);
