import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'models/streak_models.dart';

enum InvitationBox { received, sent }

class StreakRepository {
  StreakRepository(this._dio);

  final Dio _dio;

  Future<List<StreakInvitation>> invitations(InvitationBox box) async {
    final data = await _guard(
      () => _dio.get<List<dynamic>>(
        '/streak-invitations',
        queryParameters: {'box': box.name},
      ),
    );
    return data!
        .map((e) => StreakInvitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StreakInvitation> invite(int friendId) async {
    final data = await _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/streak-invitations',
        data: {'friendId': friendId},
      ),
    );
    return StreakInvitation.fromJson(data!);
  }

  Future<StreakInvitation> respond(
    int invitationId, {
    required bool accept,
  }) async {
    final data = await _guard(
      () => _dio.patch<Map<String, dynamic>>(
        '/streak-invitations/$invitationId',
        data: {'accept': accept},
      ),
    );
    return StreakInvitation.fromJson(data!);
  }

  Future<void> cancelInvitation(int invitationId) =>
      _guard(() => _dio.delete<void>('/streak-invitations/$invitationId'));

  Future<StreakDetail> detail(int streakId) async => StreakDetail.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/streaks/$streakId')))!,
  );

  Future<StreakDetail> armShield(int streakId) async => StreakDetail.fromJson(
    (await _guard(
      () => _dio.post<Map<String, dynamic>>('/streaks/$streakId/shield'),
    ))!,
  );

  Future<List<StreakHistory>> history() async {
    final data = await _guard(
      () => _dio.get<List<dynamic>>('/streaks/history'),
    );
    return data!
        .map((e) => StreakHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => StreakRepository(ref.watch(dioProvider)),
);

final receivedInvitationsProvider =
    FutureProvider.autoDispose<List<StreakInvitation>>(
      (ref) => ref
          .watch(streakRepositoryProvider)
          .invitations(InvitationBox.received),
    );

final sentInvitationsProvider =
    FutureProvider.autoDispose<List<StreakInvitation>>(
      (ref) =>
          ref.watch(streakRepositoryProvider).invitations(InvitationBox.sent),
    );

final streakDetailProvider = FutureProvider.autoDispose
    .family<StreakDetail, int>(
      (ref, id) => ref.watch(streakRepositoryProvider).detail(id),
    );

final streakHistoryProvider = FutureProvider.autoDispose<List<StreakHistory>>(
  (ref) => ref.watch(streakRepositoryProvider).history(),
);
