import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/network/providers.dart';
import 'models/activity_models.dart';

class ActivityRepository {
  ActivityRepository(this._dio);

  final Dio _dio;

  Future<PageResponse<Activity>> feed({int page = 0}) async {
    final data = await _guard(
      () => _dio.get<Map<String, dynamic>>(
        '/activities',
        queryParameters: {'page': page},
      ),
    );
    return PageResponse.fromJson(data!, Activity.fromJson);
  }

  Future<Activity> like(int id) async => Activity.fromJson(
    (await _guard(
      () => _dio.post<Map<String, dynamic>>('/activities/$id/likes'),
    ))!,
  );

  Future<void> unlike(int id) =>
      _guard(() => _dio.delete<void>('/activities/$id/likes'));

  Future<PageResponse<ActivityComment>> comments(int id, {int page = 0}) async {
    final data = await _guard(
      () => _dio.get<Map<String, dynamic>>(
        '/activities/$id/comments',
        queryParameters: {'page': page},
      ),
    );
    return PageResponse.fromJson(data!, ActivityComment.fromJson);
  }

  /// Solo se puede comentar en novedades de tus mutuals.
  Future<ActivityComment> comment(int id, String content) async =>
      ActivityComment.fromJson(
        (await _guard(
          () => _dio.post<Map<String, dynamic>>(
            '/activities/$id/comments',
            data: {'content': content},
          ),
        ))!,
      );

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(dioProvider)),
);
