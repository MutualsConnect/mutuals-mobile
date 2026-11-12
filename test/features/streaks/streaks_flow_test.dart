import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/utils/date_format.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/models/streak_models.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';
import 'package:mutuals/main.dart';

import '../../support/fakes.dart';

const _me = UserProfile(
  id: 1,
  email: 'a@x.com',
  username: 'ashly',
  displayName: 'Ashly',
  shields: 2,
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

final _invitation = StreakInvitation(
  id: 5,
  inviter: FakeSocialRepository.luis,
  invitee: const UserSummary(id: 1, username: 'ashly', displayName: 'Ashly'),
  status: InvitationStatus.pending,
  createdAt: DateTime(2026, 11, 10),
);

final _detail = StreakDetail(
  id: 9,
  friend: FakeSocialRepository.luis,
  status: StreakStatus.active,
  currentLength: 12,
  startDate: DateTime(2026, 10, 30),
  lastActiveDate: DateTime(2026, 11, 10),
);

Future<void> _pump(
  WidgetTester tester,
  FakeSocialRepository social,
  FakeStreakRepository streaks,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(social),
        streakRepositoryProvider.overrideWithValue(streaks),
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
}

const _activeMutual = MutualCard(
  mutualId: 1,
  friend: FakeSocialRepository.luis,
  streak: StreakCard(id: 9, currentLength: 12),
);

void main() {
  testWidgets('el inicio muestra las rachas activas y las invitaciones', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeSocialRepository(mutualList: [_activeMutual]),
      FakeStreakRepository(received: [_invitation]),
    );
    expect(find.text('Luis Vega'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pendiente hoy'), findsOneWidget);
    expect(find.text('Tienes 1 invitación de racha'), findsOneWidget);
  });

  testWidgets('sin rachas el inicio invita a crear la primera', (tester) async {
    await _pump(tester, FakeSocialRepository(), FakeStreakRepository());
    expect(find.text('Aún no tienes rachas'), findsOneWidget);
    expect(find.textContaining('invitación de racha'), findsNothing);
  });

  testWidgets('aceptar una invitación llama al servidor', (tester) async {
    final streaks = FakeStreakRepository(received: [_invitation]);
    await _pump(tester, FakeSocialRepository(), streaks);
    await tester.tap(find.text('Tienes 1 invitación de racha'));
    await tester.pumpAndSettle();

    expect(find.text('Quiere empezar una racha contigo'), findsOneWidget);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(streaks.responded, [(5, true)]);
    expect(find.text('Sin invitaciones'), findsOneWidget);
  });

  testWidgets('desde Mutuals se invita a una racha', (tester) async {
    final streaks = FakeStreakRepository();
    await _pump(
      tester,
      FakeSocialRepository(
        mutualList: [
          const MutualCard(mutualId: 1, friend: FakeSocialRepository.luis),
        ],
      ),
      streaks,
    );
    await tester.tap(find.text('Mutuals').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invitar'));
    await tester.pumpAndSettle();

    expect(streaks.invited, [7]);
    expect(find.text('Invitación enviada a Luis Vega'), findsOneWidget);
  });

  testWidgets('el detalle muestra los días y permite activar un escudo', (
    tester,
  ) async {
    final streaks = FakeStreakRepository(detailOf: _detail);
    await _pump(
      tester,
      FakeSocialRepository(mutualList: [_activeMutual]),
      streaks,
    );
    await tester.tap(find.text('Luis Vega'));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Racha con Luis Vega'), findsOneWidget);
    expect(find.text('Empezó'), findsOneWidget);

    await tester.ensureVisible(find.text('Activar escudo (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activar escudo (2)'));
    await tester.pumpAndSettle();
    expect(streaks.shieldArmedCalls, 1);
  });

  group('date_format', () {
    test('formatDate escribe el mes en español', () {
      expect(formatDate(DateTime(2026, 11, 11)), '11 nov 2026');
    });
    test('daysAgo describe la distancia', () {
      final now = DateTime(2026, 11, 11, 15);
      expect(daysAgo(DateTime(2026, 11, 11), now: now), 'hoy');
      expect(daysAgo(DateTime(2026, 11, 10), now: now), 'ayer');
      expect(daysAgo(DateTime(2026, 11, 8), now: now), 'hace 3 días');
    });
  });
}
