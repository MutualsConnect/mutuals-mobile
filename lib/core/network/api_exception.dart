import 'package:dio/dio.dart';

/// Error de la API, a partir del `ErrorResponse` que devuelve el backend.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;

  /// Errores por campo cuando la validación falla (400).
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => statusCode == null;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final fields = data['fieldErrors'];
      return ApiException(
        statusCode: e.response?.statusCode,
        message: (data['message'] as String?) ?? 'Ocurrió un error',
        fieldErrors: fields is Map
            ? fields.map((k, v) => MapEntry(k.toString(), v.toString()))
            : const {},
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'El servidor tardó demasiado en responder',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No se pudo conectar. Revisa tu conexión.',
        );
      default:
        return ApiException(
          statusCode: e.response?.statusCode,
          message: 'Ocurrió un error inesperado',
        );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

extension DioExceptionX on DioException {
  /// El [ApiException] asociado, aunque el error no haya pasado por el interceptor.
  ApiException get apiException => error is ApiException
      ? error as ApiException
      : ApiException.fromDio(this);
}
