import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';
import 'package:mutuals/main.dart';

import '../../support/fakes.dart';

const _ana = UserProfile(
  id: 1,
  email: 'ana@utec.edu.pe',
  username: 'ana',
  displayName: 'Ana',
  gems: 3,
  shields: 1,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.saved, this.loginError});

  final UserProfile? saved;
  final ApiException? loginError;
  var loggedOut = false;

  @override
  Future<UserProfile?> restoreSession() async => saved;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return _ana;
  }

  @override
  Future<UserProfile> register({
    required String email,
    required String username,
    required String displayName,
    required String password,
  }) async => _ana;

  @override
  Future<void> logout() async => loggedOut = true;

  @override
  Future<void> requestPasswordReset(String email) async {}
}

Future<void> _pumpApp(WidgetTester tester, _FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin sesión guardada abre el login', (tester) async {
    await _pumpApp(tester, _FakeAuthRepository());
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('con sesión guardada entra directo al inicio', (tester) async {
    await _pumpApp(tester, _FakeAuthRepository(saved: _ana));
    expect(find.textContaining('Hola, Ana'), findsOneWidget);
  });

  testWidgets('el login valida el formulario antes de enviar', (tester) async {
    await _pumpApp(tester, _FakeAuthRepository());
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('un login correcto lleva al inicio', (tester) async {
    await _pumpApp(tester, _FakeAuthRepository());
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utec.edu.pe');
    await tester.enterText(find.byType(TextFormField).at(1), 'Prueba!2026x');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hola, Ana'), findsOneWidget);
  });

  testWidgets('un login incorrecto muestra el mensaje del servidor', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _FakeAuthRepository(
        loginError: const ApiException(
          message: 'Credenciales inválidas',
          statusCode: 401,
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utec.edu.pe');
    await tester.enterText(find.byType(TextFormField).at(1), 'mala');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Credenciales inválidas'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve al login', (tester) async {
    final repo = _FakeAuthRepository(saved: _ana);
    await _pumpApp(tester, repo);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(repo.loggedOut, isTrue);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('se puede ir al registro y volver', (tester) async {
    await _pumpApp(tester, _FakeAuthRepository());
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
