import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/social/data/profile_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/main.dart';

import '../../support/fakes.dart';

const _me = UserProfile(
  id: 1,
  email: 'a@x.com',
  username: 'ashly',
  displayName: 'Ashly',
  bio: 'Hola',
);

class _Auth implements AuthRepository {
  @override
  Future<UserProfile?> restoreSession() async => _me;
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async => _me;
  @override
  Future<UserProfile> register({
    required String email,
    required String username,
    required String displayName,
    required String password,
  }) async => _me;
  @override
  Future<void> logout() async {}
  @override
  Future<void> requestPasswordReset(String email) async {}
}

Future<void> _pump(WidgetTester tester, FakeProfileRepository profile) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        profileRepositoryProvider.overrideWithValue(profile),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Buscar → abrir el perfil de Luis.
Future<void> _openLuis(WidgetTester tester) async {
  await tester.tap(find.text('Buscar').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'luis');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Luis Vega'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editar el perfil guarda nombre y biografía', (tester) async {
    final repo = FakeProfileRepository();
    await _pump(tester, repo);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    // Los campos arrancan con tus datos actuales.
    expect(find.text('Ashly'), findsOneWidget);
    expect(find.text('Hola'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '  Ashly V.  ');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Me encantan las rachas',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repo.updates.single.name, 'Ashly V.');
    expect(repo.updates.single.bio, 'Me encantan las rachas');
    expect(find.text('Perfil actualizado ✨'), findsOneWidget);
  });

  testWidgets('el nombre no puede quedar vacío', (tester) async {
    final repo = FakeProfileRepository();
    await _pump(tester, repo);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('un error del servidor al guardar se muestra en pantalla', (
    tester,
  ) async {
    final repo = FakeProfileRepository(
      error: const ApiException(
        message: 'Nombre no permitido',
        statusCode: 400,
      ),
    );
    await _pump(tester, repo);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre no permitido'), findsOneWidget);
  });

  testWidgets('bloquear a alguien pide confirmación y vuelve atrás', (
    tester,
  ) async {
    final repo = FakeProfileRepository();
    await _pump(tester, repo);
    await _openLuis(tester);

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear'));
    await tester.pumpAndSettle();
    expect(find.text('¿Bloquear a Luis Vega?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Bloquear'));
    await tester.pumpAndSettle();
    expect(repo.blocked, [7]);
    expect(find.text('Bloqueaste a Luis Vega'), findsOneWidget);
    expect(find.text('Seguir también'), findsNothing); // salimos del perfil
  });

  testWidgets('reportar exige elegir un motivo', (tester) async {
    final repo = FakeProfileRepository();
    await _pump(tester, repo);
    await _openLuis(tester);

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();

    final send = find.widgetWithText(FilledButton, 'Enviar reporte');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.text('Acoso'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Me escribe cosas ofensivas',
    );
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(repo.reports.single.id, 7);
    expect(repo.reports.single.reason, ReportReason.harassment);
    expect(repo.reports.single.description, 'Me escribe cosas ofensivas');
    expect(find.text('Reporte enviado. Gracias por avisar.'), findsOneWidget);
  });
}
