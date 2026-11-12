import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'models/subscription_models.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._dio);

  final Dio _dio;

  Future<Subscription> current() async => Subscription.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/subscriptions/me')))!,
  );

  Future<Subscription> subscribe(BillingPeriod period) async =>
      Subscription.fromJson(
        (await _guard(
          () => _dio.post<Map<String, dynamic>>(
            '/subscriptions',
            data: {
              'billingPeriod': period == BillingPeriod.yearly
                  ? 'YEARLY'
                  : 'MONTHLY',
            },
          ),
        ))!,
      );

  /// Cancela la renovación; los beneficios siguen hasta el vencimiento.
  Future<Subscription> cancel() async => Subscription.fromJson(
    (await _guard(
      () => _dio.delete<Map<String, dynamic>>('/subscriptions/me'),
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

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(dioProvider)),
);

final subscriptionProvider = FutureProvider.autoDispose<Subscription>(
  (ref) => ref.watch(subscriptionRepositoryProvider).current(),
);
