import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/location/location_service.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/interactions/data/models/interaction_models.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
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

final _detail = StreakDetail(
  id: 9,
  friend: FakeSocialRepository.luis,
  status: StreakStatus.active,
  currentLength: 12,
  startDate: DateTime(2026, 10, 30),
);

const _activeMutual = MutualCard(
  mutualId: 1,
  friend: FakeSocialRepository.luis,
  streak: StreakCard(id: 9, currentLength: 12),
);

Future<void> _pump(
  WidgetTester tester,
  FakeInteractionRepository interactions, {
  LocationService? location,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(
          FakeSocialRepository(mutualList: [_activeMutual]),
        ),
        streakRepositoryProvider.overrideWithValue(
          FakeStreakRepository(detailOf: _detail),
        ),
        interactionRepositoryProvider.overrideWithValue(interactions),
        if (location != null)
          locationServiceProvider.overrideWithValue(location),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Home → detalle de la racha → "Registrar hoy".
Future<void> _openCheckIn(WidgetTester tester) async {
  await tester.tap(find.text('Luis Vega'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Registrar hoy'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'el inicio avisa de las interacciones por confirmar y se pueden confirmar',
    (tester) async {
      final repo = FakeInteractionRepository(
        pendingList: [fakeInteraction(note: 'Café en la U')],
      );
      await _pump(tester, repo);

      expect(find.text('1 amigo espera tu confirmación'), findsOneWidget);
      await tester.tap(find.text('1 amigo espera tu confirmación'));
      await tester.pumpAndSettle();
      expect(find.text('“Café en la U”'), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.confirmed, [3]);
      expect(find.text('¡Racha con Luis Vega!'), findsOneWidget);
      expect(find.text('13 días seguidos'), findsOneWidget);
    },
  );

  testWidgets('se puede rechazar una interacción', (tester) async {
    final repo = FakeInteractionRepository(pendingList: [fakeInteraction()]);
    await _pump(tester, repo);
    await tester.tap(find.text('1 amigo espera tu confirmación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No fue así'));
    await tester.pumpAndSettle();
    expect(repo.rejected, [3]);
    expect(find.text('Todo al día'), findsOneWidget);
  });

  testWidgets('el registro manual envía la nota', (tester) async {
    final repo = FakeInteractionRepository();
    await _pump(tester, repo);
    await _openCheckIn(tester);

    await tester.tap(find.text('Confirmación manual'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Videollamada');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(repo.created, [(7, 'Videollamada')]);
  });

  testWidgets('proximidad: si el amigo aún no hizo check-in se espera', (
    tester,
  ) async {
    final repo = FakeInteractionRepository(
      proximity: const ProximityResult(
        confirmed: false,
        message: 'Esperando a que Luis también haga check-in',
      ),
    );
    await _pump(tester, repo, location: FakeLocationService());
    await _openCheckIn(tester);

    await tester.tap(find.text('Estamos juntos'));
    await tester.pumpAndSettle();

    expect(repo.proximityCalls, [(7, -12.05, -77.04)]);
    expect(
      find.text('Esperando a que Luis también haga check-in'),
      findsOneWidget,
    );
  });

  testWidgets('proximidad: si ambos hicieron check-in se celebra la racha', (
    tester,
  ) async {
    final repo = FakeInteractionRepository(
      proximity: ProximityResult(
        confirmed: true,
        message: 'ok',
        interaction: fakeInteraction(
          status: InteractionStatus.confirmed,
          streakLength: 13,
        ),
      ),
    );
    await _pump(tester, repo, location: FakeLocationService());
    await _openCheckIn(tester);

    await tester.tap(find.text('Estamos juntos'));
    await tester.pumpAndSettle();
    expect(find.text('¡Racha con Luis Vega!'), findsOneWidget);
    expect(find.text('13 días seguidos'), findsOneWidget);
  });

  testWidgets('proximidad sin permiso de ubicación muestra el motivo', (
    tester,
  ) async {
    final repo = FakeInteractionRepository();
    await _pump(
      tester,
      repo,
      location: FakeLocationService(
        error: const LocationException('Necesitamos tu permiso de ubicación'),
      ),
    );
    await _openCheckIn(tester);

    await tester.tap(find.text('Estamos juntos'));
    await tester.pumpAndSettle();
    expect(find.text('Necesitamos tu permiso de ubicación'), findsOneWidget);
    expect(repo.proximityCalls, isEmpty);
  });

  testWidgets('mi código QR se muestra con su cuenta regresiva', (
    tester,
  ) async {
    await _pump(tester, FakeInteractionRepository());
    await _openCheckIn(tester);
    await tester.tap(find.text('Mi código QR'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Muéstraselo a tu amigo'), findsOneWidget);
    expect(find.textContaining('Se renueva en'), findsOneWidget);

    // Desmontamos la pantalla para cancelar el temporizador.
    await tester.pumpWidget(const SizedBox());
  });
}
