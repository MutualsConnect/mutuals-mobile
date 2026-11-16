import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/profile_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';
import 'package:mutuals/main.dart';

import '../../support/fakes.dart';

const _me = UserProfile(
  id: 1,
  email: 'a@x.com',
  username: 'ashly',
  displayName: 'Ashly',
);

class _Auth implements AuthRepository {
  bool loggedOut = false;
  @override
  Future<UserProfile?> restoreSession() async => loggedOut ? null : _me;
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
  Future<void> logout() async => loggedOut = true;
  @override
  Future<void> requestPasswordReset(String email) async {}
}

Future<void> _open(
  WidgetTester tester,
  FakeProfileRepository repo,
  _Auth auth,
) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(repo),
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        economyRepositoryProvider.overrideWithValue(FakeEconomyRepository()),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Ajustes'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ajustes'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cambia una preferencia', (tester) async {
    final repo = FakeProfileRepository();
    await _open(tester, repo, _Auth());
    expect(repo.prefs.muteHighlights, isFalse);
    await tester.tap(find.text('Silenciar novedades destacadas'));
    await tester.pumpAndSettle();
    expect(repo.prefs.muteHighlights, isTrue);
  });

  testWidgets('quita un dispositivo', (tester) async {
    final repo = FakeProfileRepository();
    await _open(tester, repo, _Auth());
    expect(find.text('iPhone'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar dispositivo'));
    await tester.pumpAndSettle();
    expect(find.text('Ninguno registrado todavía'), findsOneWidget);
  });

  testWidgets('elimina la cuenta tras confirmar y vuelve al login', (
    tester,
  ) async {
    final repo = FakeProfileRepository();
    final auth = _Auth();
    await _open(tester, repo, auth);
    await tester.scrollUntilVisible(
      find.text('Eliminar mi cuenta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isFalse);

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isTrue);
    expect(auth.loggedOut, isTrue);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
