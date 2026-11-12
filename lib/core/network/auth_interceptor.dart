import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Agrega el access token a cada petición y, si el servidor responde 401,
/// renueva la sesión con el refresh token y reintenta la petición una vez.
///
/// Extiende [QueuedInterceptor] para que varias peticiones con 401 simultáneas
/// no intenten renovar el token a la vez (el backend rota el refresh token y
/// reutilizar uno revocado cierra todas las sesiones).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokens,
    required this.plainDio,
    required this.onSessionExpired,
  });

  final TokenStorage tokens;

  /// Cliente sin interceptores, para renovar el token y reintentar sin ciclos.
  final Dio plainDio;

  /// Se llama cuando no se pudo renovar la sesión.
  final void Function() onSessionExpired;

  static const _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/password-reset',
  ];

  bool _isPublic(RequestOptions o) => _publicPaths.any(o.path.startsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options)) {
      final token = await tokens.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        !_isPublic(request) &&
        request.extra['retried'] != true;
    if (!shouldRefresh) return handler.next(err);

    // Otra petición pudo renovar el token mientras esta esperaba en la cola.
    final current = await tokens.readAccessToken();
    final sent = request.headers['Authorization'];
    if (current != null && sent != 'Bearer $current') {
      return _retry(request, current, err, handler);
    }

    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null) return _expire(err, handler);

    try {
      final response = await plainDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = response.data!;
      final access = body['accessToken'] as String;
      await tokens.save(
        accessToken: access,
        refreshToken: body['refreshToken'] as String,
      );
      return await _retry(request, access, err, handler);
    } on DioException {
      return _expire(err, handler);
    }
  }

  Future<void> _retry(
    RequestOptions request,
    String accessToken,
    DioException original,
    ErrorInterceptorHandler handler,
  ) async {
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.extra['retried'] = true;
    try {
      handler.resolve(await plainDio.fetch<dynamic>(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _expire(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await tokens.clear();
    onSessionExpired();
    handler.next(err);
  }
}

/// Convierte cualquier [DioException] en un [ApiException] legible.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ApiException.fromDio(err)));
  }
}
