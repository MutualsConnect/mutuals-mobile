import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/features/activity/data/activity_repository.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
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

Future<void> _openFeed(WidgetTester tester, FakeActivityRepository repo) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        economyRepositoryProvider.overrideWithValue(FakeEconomyRepository()),
        activityRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Feed'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin novedades se muestra el estado vacío', (tester) async {
    await _openFeed(tester, FakeActivityRepository());
    expect(find.text('Aún no hay novedades'), findsOneWidget);
  });

  testWidgets(
    'el feed muestra las novedades con su autor y la insignia de mutual',
    (tester) async {
      await _openFeed(
        tester,
        FakeActivityRepository(
          items: [
            fakeActivity(id: 1, likes: 3, comments: 2),
            fakeActivity(
              id: 2,
              title: 'Luis llegó a 7 días de racha',
              type: 'STREAK_MILESTONE',
              fromMutual: false,
            ),
          ],
        ),
      );
      expect(find.text('Luis desbloqueó Primer fueguito'), findsOneWidget);
      expect(find.text('Luis llegó a 7 días de racha'), findsOneWidget);
      expect(find.textContaining('🤝 Mutual'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('🏅'), findsOneWidget);
    },
  );

  testWidgets('dar y quitar me gusta cambia el contador al instante', (
    tester,
  ) async {
    final repo = FakeActivityRepository(items: [fakeActivity(id: 1, likes: 3)]);
    await _openFeed(tester, repo);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();
    expect(repo.liked, [1]);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(repo.unliked, [1]);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('si falla el me gusta se revierte y se avisa', (tester) async {
    final repo = FakeActivityRepository(
      items: [fakeActivity(id: 1, likes: 3)],
      likeError: const ApiException(
        message: 'No se pudo dar me gusta',
        statusCode: 409,
      ),
    );
    await _openFeed(tester, repo);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('No se pudo dar me gusta'), findsOneWidget);
  });

  testWidgets('comentar agrega el comentario y sube el contador del feed', (
    tester,
  ) async {
    final repo = FakeActivityRepository(
      items: [fakeActivity(id: 1, comments: 1)],
      comments: [fakeComment(content: 'Qué bien')],
    );
    await _openFeed(tester, repo);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Qué bien'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '¡Felicidades!');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(repo.sentComments, [(1, '¡Felicidades!')]);
    expect(find.text('¡Felicidades!'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget); // 1 comentario + el nuevo
  });

  testWidgets('quien no es mutual no puede comentar', (tester) async {
    await _openFeed(
      tester,
      FakeActivityRepository(
        items: [fakeActivity(id: 1, canComment: false, fromMutual: false)],
      ),
    );
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();

    expect(
      find.text('Solo tus mutuals pueden comentar esta novedad.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'el feed carga más páginas hasta llenar la pantalla y al desplazarse',
    (tester) async {
      final items = [
        for (var i = 1; i <= 10; i++) fakeActivity(id: i, title: 'Novedad $i'),
      ];
      final repo = FakeActivityRepository(items: items);
      await _openFeed(tester, repo);
      expect(repo.feedPages.first, 0);
      expect(repo.feedPages.length, greaterThan(1));

      await tester.scrollUntilVisible(
        find.text('Novedad 10'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Novedad 10'), findsOneWidget);
    },
  );
}
