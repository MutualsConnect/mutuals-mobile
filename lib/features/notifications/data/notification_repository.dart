import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/network/providers.dart';
import '../../auth/application/auth_controller.dart';
import 'models/notification_models.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<PageResponse<AppNotification>> list({
    NotificationPriority? priority,
    int page = 0,
  }) async {
    final data = await _guard(() => _dio.get<Map<String, dynamic>>(
          '/notifications',
          queryParameters: {
            'page': page,
            if (priority != null) 'priority': priority.name.toUpperCase(),
          },
        ));
    return PageResponse.fromJson(data!, AppNotification.fromJson);
  }

  Future<UnreadCount> unreadCount() async => UnreadCount.fromJson(
        (await _guard(() => _dio.get<Map<String, dynamic>>('/notifications/unread-count')))!,
      );

  Future<void> markRead(int id) => _guard(() => _dio.patch<void>('/notifications/$id/read'));

  Future<void> markAllRead() => _guard(() => _dio.patch<void>('/notifications/read-all'));

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(dioProvider)));

/// Cuántas notificaciones sin leer hay. Se actualiza cada minuto mientras la
/// persona tiene la sesión abierta.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final signedIn = ref.watch(authControllerProvider.select((s) => s.status == AuthStatus.authenticated));
  if (!signedIn) return 0;
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  try {
    return (await ref.watch(notificationRepositoryProvider).unreadCount()).total;
  } on ApiException {
    return 0;
  }
});
