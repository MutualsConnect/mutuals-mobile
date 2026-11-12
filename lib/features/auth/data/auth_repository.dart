import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/token_storage.dart';
import 'models/user_profile.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  Future<UserProfile> login({
    required String email,
    required String password,
  }) =>
      _authenticate('/auth/login', {'email': email.trim(), 'password': password});

  Future<UserProfile> register({
    required String email,
    required String username,
    required String displayName,
    required String password,
  }) =>
      _authenticate('/auth/register', {
        'email': email.trim(),
        'username': username.trim(),
        'displayName': displayName.trim(),
        'password': password,
      });

  /// Si hay una sesión guardada, devuelve el usuario; si no, `null`.
  Future<UserProfile?> restoreSession() async {
    if (await _tokens.readRefreshToken() == null) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (e) {
      // Sin red conservamos la sesión guardada y avisamos con el error.
      if (e.apiException.isNetworkError) throw e.apiException;
      await _tokens.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null) {
        await _dio.post<void>('/auth/logout', data: {'refreshToken': refresh});
      }
    } on DioException {
      // Aunque falle el servidor, cerramos la sesión en el dispositivo.
    } finally {
      await _tokens.clear();
    }
  }

  Future<void> requestPasswordReset(String email) =>
      _guard(() => _dio.post<void>('/auth/password-reset', data: {'email': email.trim()}));

  Future<UserProfile> _authenticate(String path, Map<String, dynamic> body) async {
    final data = await _guard(() => _dio.post<Map<String, dynamic>>(path, data: body));
    await _tokens.save(
      accessToken: data!['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<T?> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw e.apiException;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
