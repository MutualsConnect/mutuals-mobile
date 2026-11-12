import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

/// Crea el cliente HTTP de la app.
Dio createApiClient({
  required TokenStorage tokens,
  required void Function() onSessionExpired,
  String? baseUrl,
  HttpClientAdapter? adapter,
}) {
  BaseOptions options() => BaseOptions(
    baseUrl: baseUrl ?? ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  );

  final plain = Dio(options());
  final dio = Dio(options());
  if (adapter != null) {
    plain.httpClientAdapter = adapter;
    dio.httpClientAdapter = adapter;
  }

  dio.interceptors.addAll([
    AuthInterceptor(
      tokens: tokens,
      plainDio: plain,
      onSessionExpired: onSessionExpired,
    ),
    ErrorInterceptor(),
  ]);
  return dio;
}
