import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/features/activity/data/activity_repository.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/gamification/data/gamification_repository.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';
import 'package:mutuals/features/subscription/data/models/subscription_models.dart';
import 'package:mutuals/features/subscription/data/subscription_repository.dart';
import 'package:mutuals/features/wrapped/data/models/wrapped_models.dart';
import 'package:mutuals/features/wrapped/data/wrapped_repository.dart';
import 'package:mutuals/features/wrapped/presentation/wrapped_slides.dart';
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

Future<void> _open(
  WidgetTester tester,
  String option, {
  FakeWrappedRepository? wrapped,
  FakeSubscriptionRepository? subscription,
}) async {
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
        gamificationRepositoryProvider.overrideWithValue(
          FakeGamificationRepository(),
        ),
        activityRepositoryProvider.overrideWithValue(FakeActivityRepository()),
        wrappedRepositoryProvider.overrideWithValue(
          wrapped ?? FakeWrappedRepository(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          subscription ?? FakeSubscriptionRepository(),
        ),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.textContaining(option),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.textContaining(option));
  await tester.pumpAndSettle();
}

/// Cierra el visor de historias para cancelar su temporizador.
Future<void> _closeStories(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close_rounded));
  await tester.pumpAndSettle();
}

void main() {
  group('construcción de las pantallas', () {
    test('un periodo vacío solo tiene la portada y un mensaje', () {
      final slides = buildWrappedSlides(
        periodLabel: 'Octubre 2026',
        stats: const WrappedStats(),
      );
      expect(slides.map((s) => s.kind), [SlideKind.intro, SlideKind.empty]);
    });

    test('un periodo con datos incluye solo lo que tiene algo que contar', () {
      final slides = buildWrappedSlides(
        periodLabel: 'Octubre 2026',
        stats: const WrappedStats(
          interactions: 5,
          activeDays: 3,
          longestStreak: 0,
          newMutuals: 1,
        ),
      );
      expect(slides.map((s) => s.kind), [
        SlideKind.intro,
        SlideKind.counter, // interacciones
        SlideKind.counter, // días activo
        SlideKind.counter, // mutuals nuevos
        SlideKind.outro,
      ]);
      expect(slides[1].value, 5);
    });

    test('con todos los datos aparecen mutual favorito y métodos', () {
      final slides = buildWrappedSlides(
        periodLabel: 'x',
        stats: fakeWrapped().stats,
      );
      expect(
        slides.map((s) => s.kind),
        containsAll([SlideKind.topMutual, SlideKind.methods]),
      );
      expect(slides.last.kind, SlideKind.outro);
    });

    test('el Wrapped histórico del plan gratis invita a Plus; con Plus no', () {
      const friend = FriendWrapped(
        friend: FakeSocialRepository.luis,
        currentlyMutual: true,
        totalStreaks: 2,
        bestStreak: 9,
        interactions: 30,
      );
      const stats = WrappedStats(interactions: 30);
      final free = buildWrappedSlides(
        periodLabel: 'x',
        stats: stats,
        allTime: const AllTimeWrapped(
          overall: stats,
          fullAccess: false,
          friends: [friend],
        ),
      );
      final plus = buildWrappedSlides(
        periodLabel: 'x',
        stats: stats,
        allTime: const AllTimeWrapped(
          overall: stats,
          fullAccess: true,
          friends: [friend],
        ),
      );
      expect(
        free.firstWhere((s) => s.kind == SlideKind.friends).showPlusUpsell,
        isTrue,
      );
      expect(
        plus.firstWhere((s) => s.kind == SlideKind.friends).showPlusUpsell,
        isFalse,
      );
    });

    test('las etiquetas de periodo se escriben en español', () {
      expect(wrappedPeriodLabel('2026-11'), 'Noviembre 2026');
      expect(wrappedPeriodLabel('2026'), 'Año 2026');
      expect(wrappedPeriodLabel('ALL'), 'Todo el tiempo');
    });

    test('los beneficios del backend se traducen', () {
      expect(
        translateBenefit('Unlimited active streaks'),
        'Rachas activas ilimitadas',
      );
      expect(translateBenefit('Algo nuevo'), 'Algo nuevo');
    });
  });

  testWidgets('sin Wrapped generados se explica cuándo llega el primero', (
    tester,
  ) async {
    await _open(tester, 'Mi Wrapped');
    expect(find.text('Todo el tiempo'), findsOneWidget);
    expect(find.text('Tu primer Wrapped está en camino'), findsOneWidget);
  });

  testWidgets('la lista muestra cada periodo y abre sus historias', (
    tester,
  ) async {
    await _open(
      tester,
      'Mi Wrapped',
      wrapped: FakeWrappedRepository(items: [fakeWrapped()]),
    );
    expect(find.text('Octubre 2026'), findsOneWidget);

    await tester.tap(find.text('Octubre 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Tu Wrapped'), findsOneWidget);

    // Tocar a la derecha avanza a la siguiente pantalla.
    await tester.tapAt(const Offset(350, 600));
    await tester.pumpAndSettle();
    expect(find.text('interacciones con tus amigos'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    await _closeStories(tester);
  });

  testWidgets('las historias avanzan solas', (tester) async {
    await _open(
      tester,
      'Mi Wrapped',
      wrapped: FakeWrappedRepository(items: [fakeWrapped()]),
    );
    await tester.tap(find.text('Octubre 2026'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('interacciones con tus amigos'), findsOneWidget);
    await _closeStories(tester);
  });

  testWidgets(
    'el Wrapped histórico del plan gratis ofrece Plus para ver a todos los amigos',
    (tester) async {
      const friend = FriendWrapped(
        friend: FakeSocialRepository.luis,
        currentlyMutual: true,
        totalStreaks: 1,
        bestStreak: 9,
        interactions: 30,
      );
      final repo = FakeWrappedRepository(
        allTime: const AllTimeWrapped(
          overall: WrappedStats(interactions: 30),
          fullAccess: false,
          friends: [friend],
        ),
      );
      await _open(tester, 'Mi Wrapped', wrapped: repo);
      await tester.tap(find.text('Todo el tiempo'));
      await tester.pumpAndSettle();

      // Pasamos las pantallas hasta la de amigos.
      for (
        var i = 0;
        i < 5 && find.text('Tus amigos').evaluate().isEmpty;
        i++
      ) {
        await tester.tapAt(const Offset(350, 600));
        await tester.pumpAndSettle();
      }
      expect(find.text('Tus amigos'), findsOneWidget);
      expect(find.text('Luis Vega'), findsOneWidget);
      await tester.tap(find.text('⭐ Ver todos con Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Lleva tus rachas más lejos'), findsOneWidget);
    },
  );

  testWidgets('Plus: suscribirse cambia el plan', (tester) async {
    final sub = FakeSubscriptionRepository();
    await _open(tester, 'Mutuals Plus', subscription: sub);
    expect(find.text('Lleva tus rachas más lejos'), findsOneWidget);
    expect(find.text('Rachas activas ilimitadas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Demostración'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Demostración'), findsOneWidget);

    await tester.tap(find.text('Suscribirme · Anual'));
    await tester.pumpAndSettle();
    expect(sub.subscribed, [BillingPeriod.yearly]);
    expect(find.text('Eres Mutuals Plus'), findsOneWidget);
    expect(find.text('Cancelar renovación'), findsOneWidget);
  });

  testWidgets(
    'Plus: cancelar la renovación pide confirmar y conserva los beneficios hasta el vencimiento',
    (tester) async {
      final sub = FakeSubscriptionRepository(
        fakeSubscription(plan: SubscriptionPlan.plus),
      );
      await _open(tester, 'Mutuals Plus', subscription: sub);
      expect(find.text('Eres Mutuals Plus'), findsOneWidget);
      expect(find.text('Se renueva el 12 dic 2026.'), findsOneWidget);

      await tester.tap(find.text('Cancelar renovación'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar la renovación?'), findsOneWidget);
      await tester.tap(find.text('Cancelar renovación').last);
      await tester.pumpAndSettle();

      expect(sub.cancelCalls, 1);
      expect(
        find.text('Tus beneficios terminan el 12 dic 2026.'),
        findsOneWidget,
      );
      expect(find.text('Cancelar renovación'), findsNothing);
    },
  );
}
