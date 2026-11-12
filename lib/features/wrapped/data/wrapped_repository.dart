import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'models/wrapped_models.dart';

class WrappedRepository {
  WrappedRepository(this._dio);

  final Dio _dio;

  /// Tus Wrapped mensuales y anuales ya generados, del más reciente al más antiguo.
  Future<List<WrappedSummary>> mine() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/wrapped'));
    return data!
        .map((e) => WrappedSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AllTimeWrapped> allTime() async => AllTimeWrapped.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/wrapped/all-time')))!,
  );

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final wrappedRepositoryProvider = Provider<WrappedRepository>(
  (ref) => WrappedRepository(ref.watch(dioProvider)),
);

final wrappedListProvider = FutureProvider.autoDispose<List<WrappedSummary>>(
  (ref) => ref.watch(wrappedRepositoryProvider).mine(),
);

final allTimeWrappedProvider = FutureProvider.autoDispose<AllTimeWrapped>(
  (ref) => ref.watch(wrappedRepositoryProvider).allTime(),
);
