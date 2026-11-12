// Prueba contra el backend real (localhost:8080). Se omite por defecto.
//
//   MUTUALS_E2E=1 flutter test test/integration/backend_smoke_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_client.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/storage/token_storage.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';

void main() {
  final enabled = Platform.environment.containsKey('MUTUALS_E2E');

  group('backend real', skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar', () {
    late InMemoryTokenStorage tokens;
    late AuthRepository repo;

    setUp(() {
      tokens = InMemoryTokenStorage();
      final dio = createApiClient(
        tokens: tokens,
        onSessionExpired: () {},
        baseUrl: 'http://localhost:8080/api/v1',
      );
      repo = AuthRepository(dio, tokens);
    });

    test('registro, restaurar sesión y cerrar sesión', () async {
      final id = DateTime.now().millisecondsSinceEpoch;
      final user = await repo.register(
        email: 'e2e$id@example.com',
        username: 'e2e$id',
        displayName: 'E2E Test',
        password: 'Prueba!2026x',
      );
      expect(user.username, 'e2e$id');
      expect(await tokens.readRefreshToken(), isNotNull);

      final restored = await repo.restoreSession();
      expect(restored?.email, 'e2e$id@example.com');

      await repo.logout();
      expect(await tokens.readRefreshToken(), isNull);
      expect(await repo.restoreSession(), isNull);
    });

    test('login con credenciales incorrectas lanza ApiException 401', () async {
      await expectLater(
        repo.login(email: 'nadie@example.com', password: 'Mala!2026x'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('registro con datos inválidos devuelve errores por campo', () async {
      try {
        await repo.register(
          email: 'mal',
          username: 'X',
          displayName: '',
          password: '123',
        );
        fail('debió lanzar');
      } on ApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.fieldErrors.keys, containsAll(['email', 'username', 'password']));
      }
    });

    test('el correo repetido se rechaza', () async {
      await expectLater(
        repo.register(
          email: 'ashly.test@example.com',
          username: 'otro.usuario',
          displayName: 'Otro',
          password: 'Prueba!2026x',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );
    });
  });
}
