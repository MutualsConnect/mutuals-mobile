import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'models/interaction_models.dart';

class InteractionRepository {
  InteractionRepository(this._dio);

  final Dio _dio;

  /// Registra una interacción manual; el amigo debe confirmarla en 24 h.
  Future<Interaction> create(int friendId, {String? note}) async => Interaction.fromJson(
        (await _guard(() => _dio.post<Map<String, dynamic>>(
              '/interactions',
              data: {'friendId': friendId, if (note != null && note.isNotEmpty) 'note': note},
            )))!,
      );

  Future<Interaction> confirm(int id) async => Interaction.fromJson(
        (await _guard(() => _dio.post<Map<String, dynamic>>('/interactions/$id/confirm')))!,
      );

  Future<Interaction> reject(int id) async => Interaction.fromJson(
        (await _guard(() => _dio.post<Map<String, dynamic>>('/interactions/$id/reject')))!,
      );

  /// Interacciones que esperan tu confirmación.
  Future<List<Interaction>> pending() async {
    final data = await _guard(() => _dio.get<List<dynamic>>('/interactions/pending'));
    return data!.map((e) => Interaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QrCode> myQr() async =>
      QrCode.fromJson((await _guard(() => _dio.get<Map<String, dynamic>>('/qr-codes/me')))!);

  /// Escanea el QR de un mutual: confirma la interacción al instante.
  Future<Interaction> checkInWithQr(String token) async => Interaction.fromJson(
        (await _guard(() => _dio.post<Map<String, dynamic>>('/check-ins/qr', data: {'token': token})))!,
      );

  Future<ProximityResult> checkInByProximity({
    required int friendId,
    required double latitude,
    required double longitude,
  }) async =>
      ProximityResult.fromJson(
        (await _guard(() => _dio.post<Map<String, dynamic>>(
              '/check-ins/proximity',
              data: {'friendId': friendId, 'latitude': latitude, 'longitude': longitude},
            )))!,
      );

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final interactionRepositoryProvider =
    Provider<InteractionRepository>((ref) => InteractionRepository(ref.watch(dioProvider)));

final pendingInteractionsProvider = FutureProvider.autoDispose<List<Interaction>>(
  (ref) => ref.watch(interactionRepositoryProvider).pending(),
);
