import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/network/providers.dart';
import 'models/economy_models.dart';

class EconomyRepository {
  EconomyRepository(this._dio);

  final Dio _dio;

  Future<Wallet> wallet() async => Wallet.fromJson(
    (await _guard(() => _dio.get<Map<String, dynamic>>('/wallet')))!,
  );

  Future<PageResponse<WalletTransaction>> transactions({int page = 0}) async {
    final data = await _guard(
      () => _dio.get<Map<String, dynamic>>(
        '/wallet/transactions',
        queryParameters: {'page': page},
      ),
    );
    return PageResponse.fromJson(data!, WalletTransaction.fromJson);
  }

  /// Compra de 1 a 5 escudos con gemas.
  Future<Wallet> purchaseShields(int quantity) async => Wallet.fromJson(
    (await _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/shields/purchase',
        data: {'quantity': quantity},
      ),
    ))!,
  );

  /// Regala uno de tus escudos a un mutual.
  Future<Wallet> giftShield(int friendId) async => Wallet.fromJson(
    (await _guard(
      () => _dio.post<Map<String, dynamic>>(
        '/shields/gifts',
        data: {'friendId': friendId},
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

final economyRepositoryProvider = Provider<EconomyRepository>(
  (ref) => EconomyRepository(ref.watch(dioProvider)),
);

final walletProvider = FutureProvider.autoDispose<Wallet>(
  (ref) => ref.watch(economyRepositoryProvider).wallet(),
);
