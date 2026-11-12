import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/utils/date_format.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/models/notification_models.dart';
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

Future<void> _pump(WidgetTester tester, FakeNotificationRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(FakeSocialRepository()),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openNotifications(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.notifications_none_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la campana muestra cuántas notificaciones no leídas hay', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeNotificationRepository(
        items: [
          fakeNotification(id: 1),
          fakeNotification(id: 2),
          fakeNotification(id: 3, read: true),
        ],
      ),
    );
    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('sin notificaciones se muestra el estado vacío', (tester) async {
    await _pump(tester, FakeNotificationRepository());
    await _openNotifications(tester);
    expect(find.text('Sin notificaciones'), findsOneWidget);
  });

  testWidgets('tocar una notificación la marca como leída y abre su pantalla', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(items: [fakeNotification(id: 7)]);
    await _pump(tester, repo);
    await _openNotifications(tester);

    await tester.tap(find.text('Luis quiere empezar una racha contigo'));
    await tester.pumpAndSettle();

    expect(repo.read, [7]);
    expect(find.text('Invitaciones'), findsOneWidget);
  });

  testWidgets('marcar todas como leídas', (tester) async {
    final repo = FakeNotificationRepository(
      items: [fakeNotification(id: 1), fakeNotification(id: 2)],
    );
    await _pump(tester, repo);
    await _openNotifications(tester);

    await tester.tap(find.text('Marcar todas'));
    await tester.pumpAndSettle();

    expect(repo.readAllCalls, 1);
    expect(find.text('Marcar todas'), findsNothing);
  });

  testWidgets('el filtro Importantes pide solo las de prioridad alta', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [
        fakeNotification(
          id: 1,
          title: 'Importante',
          priority: NotificationPriority.high,
        ),
        fakeNotification(
          id: 2,
          title: 'Menor',
          priority: NotificationPriority.low,
          referenceType: null,
        ),
      ],
    );
    await _pump(tester, repo);
    await _openNotifications(tester);
    expect(find.text('Menor'), findsOneWidget);

    await tester.tap(find.text('Importantes'));
    await tester.pumpAndSettle();
    expect(repo.filtersRequested.last, NotificationPriority.high);
    expect(find.text('Menor'), findsNothing);
    expect(find.text('Importante'), findsOneWidget);
  });

  testWidgets('carga más páginas hasta llenar la pantalla y al desplazarse', (
    tester,
  ) async {
    final items = [
      for (var i = 1; i <= 12; i++)
        fakeNotification(id: i, title: 'Aviso $i', referenceType: null),
    ];
    final repo = FakeNotificationRepository(items: items);
    await _pump(tester, repo);
    await _openNotifications(tester);

    // La primera página (2 avisos) no llena la pantalla: pide la siguiente sola.
    expect(repo.pagesRequested.first, 0);
    expect(repo.pagesRequested.length, greaterThan(1));

    await tester.scrollUntilVisible(
      find.text('Aviso 12'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Aviso 12'), findsOneWidget);
    expect(repo.pagesRequested.toSet().length, 6);
  });

  group('AppNotification y timeAgo', () {
    test('cada referencia lleva a su pantalla', () {
      expect(
        fakeNotification(referenceType: 'USER', referenceId: 3).route,
        '/users/3',
      );
      expect(
        fakeNotification(referenceType: 'STREAK', referenceId: 9).route,
        '/streaks/9',
      );
      expect(
        fakeNotification(referenceType: 'INTERACTION', referenceId: 2).route,
        '/pending',
      );
      expect(
        fakeNotification(referenceType: 'WRAPPED', referenceId: 1).route,
        isNull,
      );
      expect(
        fakeNotification(referenceType: null, referenceId: null).route,
        isNull,
      );
    });

    test('timeAgo escribe el tiempo en español', () {
      final now = DateTime(2026, 11, 12, 12);
      expect(timeAgo(now, now: now), 'ahora');
      expect(
        timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        'hace 5 min',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        'hace 3 h',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 1, hours: 1)), now: now),
        'ayer',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 3)), now: now),
        'hace 3 días',
      );
    });
  });
}
