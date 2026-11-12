import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/media/photo_picker.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/gamification/data/gamification_repository.dart';
import 'package:mutuals/features/gamification/data/models/gamification_models.dart';
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
  gems: 50,
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

/// Abre la app y entra a una opción de la pestaña Perfil.
Future<void> _open(
  WidgetTester tester,
  String option, {
  required FakeGamificationRepository repo,
  PhotoPicker? picker,
}) async {
  // Tamaño de un iPhone: la ventana de pruebas por defecto es ancha y baja.
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
        gamificationRepositoryProvider.overrideWithValue(repo),
        if (picker != null) photoPickerProvider.overrideWithValue(picker),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(option),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(option));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('logros: cuenta los desbloqueados y bloquea el resto', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      achievementList: [
        fakeAchievement(code: 'A', name: 'Primer fueguito', unlocked: true),
        fakeAchievement(code: 'B', name: 'Una semana juntos'),
        fakeAchievement(code: 'C', name: 'Un mes imparable'),
      ],
    );
    await _open(tester, 'Logros', repo: repo);

    expect(find.text('1 de 3 desbloqueados'), findsOneWidget);
    expect(find.text('Desbloqueado el 10 nov 2026'), findsOneWidget);
    expect(find.text('🔒'), findsNWidgets(2));
  });

  testWidgets('avatar: comprar un ítem y luego equiparlo', (tester) async {
    final repo = FakeGamificationRepository(
      items: [
        fakeAvatarItem(
          id: 1,
          code: 'BASE_CLASSIC',
          name: 'Base clásica',
          layer: AvatarLayer.base,
          price: 0,
          owned: true,
          equipped: true,
        ),
        fakeAvatarItem(id: 2, name: 'Cabello rizado'),
      ],
    );
    await _open(tester, 'Mi avatar', repo: repo);

    // Pestaña Base: el ítem que ya llevas puesto.
    expect(find.text('Equipado ✓'), findsOneWidget);

    await tester.tap(find.text('Cabello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar · 20 💎'));
    await tester.pumpAndSettle();
    expect(repo.purchased, [2]);
    expect(find.text('Equipar'), findsOneWidget);

    await tester.tap(find.text('Equipar'));
    await tester.pumpAndSettle();
    expect(repo.equipped, [2]);
    expect(find.text('Equipado ✓'), findsOneWidget);
  });

  testWidgets('avatar: lo exclusivo de Plus no se puede comprar', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      items: [
        fakeAvatarItem(
          id: 3,
          code: 'OUTFIT_GOLD',
          name: 'Traje dorado',
          layer: AvatarLayer.outfit,
          premiumOnly: true,
        ),
      ],
    );
    await _open(tester, 'Mi avatar', repo: repo);
    await tester.tap(find.text('Ropa'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '⭐ Solo Plus'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('desafíos: sin desafíos explica cuándo llegan', (tester) async {
    await _open(
      tester,
      'Desafíos de la semana',
      repo: FakeGamificationRepository(),
    );
    expect(find.text('Sin desafíos esta semana'), findsOneWidget);
  });

  testWidgets('desafíos: se envía la parte propia con texto', (tester) async {
    final repo = FakeGamificationRepository(challengeList: [fakeChallenge()]);
    await _open(tester, 'Desafíos de la semana', repo: repo);

    expect(find.text('Pregunta del día'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    await tester.tap(find.text('Pregunta del día'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      '¿Cuál fue tu primer recuerdo?',
    );
    await tester.tap(find.text('Enviar mi parte'));
    await tester.pumpAndSettle();

    expect(repo.submissions.single.id, 5);
    expect(repo.submissions.single.content, '¿Cuál fue tu primer recuerdo?');
    expect(repo.submissions.single.photo, isNull);
  });

  testWidgets('desafíos: si pide foto no se puede enviar sin ella', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      challengeList: [fakeChallenge(requiresPhoto: true)],
    );
    await _open(
      tester,
      'Desafíos de la semana',
      repo: repo,
      picker: FakePhotoPicker(null),
    );
    await tester.tap(find.text('Pregunta del día'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Aquí estamos');
    await tester.tap(find.text('Enviar mi parte'));
    await tester.pumpAndSettle();
    expect(find.text('Este desafío necesita una foto.'), findsOneWidget);
    expect(repo.submissions, isEmpty);
  });

  testWidgets('desafíos: con foto elegida se envía junto al texto', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      challengeList: [fakeChallenge(requiresPhoto: true)],
    );
    await _open(
      tester,
      'Desafíos de la semana',
      repo: repo,
      picker: FakePhotoPicker('/tmp/foto-de-prueba.jpg'),
    );
    await tester.tap(find.text('Pregunta del día'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar foto (obligatoria)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Juntos');
    await tester.ensureVisible(find.text('Enviar mi parte'));
    await tester.tap(find.text('Enviar mi parte'));
    await tester.pumpAndSettle();

    expect(repo.submissions.single.photo, '/tmp/foto-de-prueba.jpg');
  });

  testWidgets(
    'desafíos: la respuesta del otro está oculta hasta que ambos cumplan',
    (tester) async {
      final repo = FakeGamificationRepository(
        challengeList: [
          fakeChallenge(
            submittedByMe: true,
            submissions: [
              const ChallengeSubmission(
                user: FakeSocialRepository.luis,
                revealed: false,
              ),
            ],
          ),
        ],
      );
      await _open(tester, 'Desafíos de la semana', repo: repo);
      expect(find.text('Esperando a Luis Vega'), findsOneWidget);
      await tester.tap(find.text('Pregunta del día'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Se mostrará cuando ambos cumplan'),
        findsOneWidget,
      );
      expect(find.text('Enviar mi parte'), findsNothing);
    },
  );
}
