import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
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

class _FakeAuth implements AuthRepository {
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

Future<void> _pump(WidgetTester tester, FakeSocialRepository social) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuth()),
        socialRepositoryProvider.overrideWithValue(social),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la lista de mutuals vacía invita a buscar amigos', (
    tester,
  ) async {
    await _pump(tester, FakeSocialRepository());
    await tester.tap(find.text('Mutuals').last);
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes mutuals'), findsOneWidget);
  });

  testWidgets('muestra cada mutual con su racha', (tester) async {
    await _pump(
      tester,
      FakeSocialRepository(
        mutualList: [
          const MutualCard(
            mutualId: 1,
            friend: FakeSocialRepository.luis,
            streak: StreakCard(id: 9, currentLength: 12, atRisk: true),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Mutuals').last);
    await tester.pumpAndSettle();
    expect(find.text('Luis Vega'), findsOneWidget);
    expect(find.text('En riesgo'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('buscar, abrir el perfil y seguir', (tester) async {
    final social = FakeSocialRepository();
    await _pump(tester, social);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'luis');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Vega'));
    await tester.pumpAndSettle();

    expect(find.text('Seguir también'), findsOneWidget);
    await tester.tap(find.text('Seguir también'));
    await tester.pumpAndSettle();
    expect(social.following, isTrue);
    expect(find.widgetWithText(OutlinedButton, 'Siguiendo'), findsOneWidget);
  });

  testWidgets('dejar de seguir con racha activa pide confirmación', (
    tester,
  ) async {
    final social = FakeSocialRepository(unfollowNeedsConfirm: true)
      ..following = true;
    await _pump(tester, social);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'luis');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Vega'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Siguiendo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Dejar de seguir?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Dejar de seguir'));
    await tester.pumpAndSettle();
    expect(social.unfollowCalls, [false, true]);
    expect(find.text('Seguir también'), findsOneWidget);
  });

  testWidgets('sin coincidencias muestra "Sin resultados"', (tester) async {
    await _pump(tester, FakeSocialRepository());
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Sin resultados'), findsOneWidget);
  });
}
