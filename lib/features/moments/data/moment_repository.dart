import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/photo_upload.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/network/providers.dart';
import '../../auth/application/auth_controller.dart';
import 'models/moment_models.dart';

class MomentRepository {
  MomentRepository(this._dio);

  final Dio _dio;

  /// Lanza un momento a un amigo con racha activa.
  Future<Moment> start(int friendId) async => Moment.fromJson(
    (await _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/moments',
        data: {'friendId': friendId},
      ),
    ))!,
  );

  /// Momentos abiertos en los que participas.
  Future<List<Moment>> active() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/moments/active'));
    return data!
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Moment> get(int id) async => Moment.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/moments/$id')))!,
  );

  /// Recuerdos: momentos completados con las dos fotos reveladas.
  Future<PageResponse<Moment>> history({int page = 0}) async {
    final data = await _guard(
      () => _dio.get<Map<String, dynamic>>(
        '/moments/history',
        queryParameters: {'page': page},
      ),
    );
    return PageResponse.fromJson(data!, Moment.fromJson);
  }

  /// Sube tu foto (ruta de un archivo local). Al llegar la segunda foto a tiempo la racha se confirma.
  Future<Moment> submitPhoto(
    int id,
    String photoPath, {
    String? caption,
  }) async {
    final form = FormData.fromMap({
      'photo': await photoPart(photoPath),
      if (caption != null && caption.trim().isNotEmpty)
        'caption': caption.trim(),
    });
    return Moment.fromJson(
      (await _guard(
        () => _dio.post<Map<String, dynamic>>('/moments/$id/photo', data: form),
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

final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => MomentRepository(ref.watch(dioProvider)),
);

/// Cada cuánto se consulta si hay un momento nuevo. Rápido mientras hay uno abierto,
/// porque cada segundo cuenta; más tranquilo el resto del tiempo.
const _busyPoll = Duration(seconds: 3);
const _idlePoll = Duration(seconds: 12);

/// Momentos abiertos. Se actualiza solo mientras la sesión está abierta, así quien
/// recibe un momento lo ve aparecer en el inicio sin tener que hacer nada.
final activeMomentsProvider = FutureProvider<List<Moment>>((ref) async {
  final signedIn = ref.watch(
    authControllerProvider.select((s) => s.status == AuthStatus.authenticated),
  );
  if (!signedIn) return const [];
  List<Moment> moments;
  try {
    moments = await ref.watch(momentRepositoryProvider).active();
  } on ApiException {
    moments = const [];
  }
  final timer = Timer(
    moments.any((m) => m.isOpen) ? _busyPoll : _idlePoll,
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return moments;
});

/// Un momento concreto, que se refresca solo mientras sigue abierto: así se ve
/// cuándo tu amigo sube su foto y cuándo se revela todo.
final momentProvider = FutureProvider.autoDispose.family<Moment, int>((
  ref,
  id,
) async {
  final moment = await ref.watch(momentRepositoryProvider).get(id);
  if (moment.isOpen) {
    final timer = Timer(const Duration(seconds: 2), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return moment;
});

final momentHistoryProvider = FutureProvider.autoDispose<List<Moment>>(
  (ref) async => (await ref.watch(momentRepositoryProvider).history()).content,
);
