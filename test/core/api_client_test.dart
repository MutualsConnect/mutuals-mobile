import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_client.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/storage/token_storage.dart';

typedef _Handler = ResponseBody Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  late InMemoryTokenStorage tokens;
  var expired = 0;

  setUp(() {
    tokens = InMemoryTokenStorage();
    expired = 0;
  });

  Dio build(_FakeAdapter adapter) => createApiClient(
        tokens: tokens,
        onSessionExpired: () => expired++,
        baseUrl: 'http://test/api/v1',
        adapter: adapter,
      );

  test('agrega el access token a las rutas protegidas', () async {
    await tokens.save(accessToken: 'abc', refreshToken: 'r1');
    final adapter = _FakeAdapter((_) => _json(200, {'ok': true}));
    await build(adapter).get('/mutuals');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test('no agrega token en /auth/login', () async {
    await tokens.save(accessToken: 'abc', refreshToken: 'r1');
    final adapter = _FakeAdapter((_) => _json(200, {'ok': true}));
    await build(adapter).post('/auth/login', data: {});

    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('ante un 401 renueva el token y reintenta la petición', () async {
    await tokens.save(accessToken: 'viejo', refreshToken: 'r1');
    final adapter = _FakeAdapter((o) {
      if (o.path == '/auth/refresh') {
        return _json(200, {'accessToken': 'nuevo', 'refreshToken': 'r2'});
      }
      return o.headers['Authorization'] == 'Bearer nuevo'
          ? _json(200, {'ok': true})
          : _json(401, {'message': 'expired'});
    });

    final response = await build(adapter).get('/mutuals');

    expect(response.statusCode, 200);
    expect(await tokens.readAccessToken(), 'nuevo');
    expect(await tokens.readRefreshToken(), 'r2');
    expect(expired, 0);
  });

  test('si no se puede renovar, limpia la sesión y avisa', () async {
    await tokens.save(accessToken: 'viejo', refreshToken: 'r1');
    final adapter = _FakeAdapter((_) => _json(401, {'message': 'invalid'}));

    await expectLater(
      build(adapter).get('/mutuals'),
      throwsA(isA<DioException>()),
    );

    expect(await tokens.readAccessToken(), isNull);
    expect(expired, 1);
  });

  test('un 401 en login no intenta renovar (credenciales inválidas)', () async {
    final adapter = _FakeAdapter(
      (_) => _json(401, {'status': 401, 'message': 'Invalid credentials'}),
    );

    try {
      await build(adapter).post('/auth/login', data: {});
      fail('debió lanzar');
    } on DioException catch (e) {
      expect(e.apiException.message, 'Invalid credentials');
      expect(e.apiException.isUnauthorized, isTrue);
    }
    expect(adapter.requests.length, 1);
    expect(expired, 0);
  });

  test('ApiException lee los errores por campo del backend', () async {
    final adapter = _FakeAdapter(
      (_) => _json(400, {
        'status': 400,
        'message': 'Validation failed',
        'fieldErrors': {'email': 'must be a well-formed email address'},
      }),
    );

    try {
      await build(adapter).post('/auth/register', data: {});
      fail('debió lanzar');
    } on DioException catch (e) {
      final api = e.apiException;
      expect(api.statusCode, 400);
      expect(api.fieldErrors['email'], contains('email'));
    }
  });
}
