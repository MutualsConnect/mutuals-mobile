import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/economy/data/models/economy_models.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/models/social_models.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';
import 'package:mutuals/main.dart';

import '../../support/fakes.dart';

const _me = UserProfile(
  id: 1,
  email: 'a@x.com',
  username: 'ashly',
  displayName: 'Ashly',
  gems: 45,
  shields: 1,
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

Future<void> _pump(
  WidgetTester tester,
  FakeEconomyRepository economy, {
  List<MutualCard> mutuals = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_Auth()),
        socialRepositoryProvider.overrideWithValue(
          FakeSocialRepository(mutualList: mutuals),
        ),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        interactionRepositoryProvider.overrideWithValue(
          FakeInteractionRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        economyRepositoryProvider.overrideWithValue(economy),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
  // Las tarjetas de gemas y escudos del inicio llevan a la billetera.
  await tester.tap(find.text('Gemas'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el saldo y el precio del escudo', (tester) async {
    await _pump(tester, FakeEconomyRepository(gems: 45, shields: 1));
    expect(find.text('45'), findsOneWidget);
    expect(find.textContaining('Cada escudo cuesta 20'), findsOneWidget);
    expect(find.text('Comprar por 20 💎'), findsOneWidget);
  });

  testWidgets('comprar escudos descuenta las gemas', (tester) async {
    final economy = FakeEconomyRepository(gems: 45, shields: 1);
    await _pump(tester, economy);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Comprar por 40 💎'), findsOneWidget);

    await tester.tap(find.text('Comprar por 40 💎'));
    await tester.pumpAndSettle();

    expect(economy.purchases, [2]);
    expect(find.text('3'), findsOneWidget); // escudos: 1 + 2
    expect(find.text('5'), findsOneWidget); // gemas: 45 - 40
  });

  testWidgets(
    'si no alcanzan las gemas el botón se desactiva y explica cuánto falta',
    (tester) async {
      await _pump(tester, FakeEconomyRepository(gems: 5));
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Comprar por 20 💎'),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('Te faltan 15'), findsOneWidget);
    },
  );

  testWidgets('el error del servidor se muestra al comprar', (tester) async {
    await _pump(
      tester,
      FakeEconomyRepository(
        gems: 45,
        purchaseError: const ApiException(
          message: 'Saldo insuficiente',
          statusCode: 409,
        ),
      ),
    );
    await tester.tap(find.text('Comprar por 20 💎'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo insuficiente'), findsOneWidget);
  });

  testWidgets('regalar un escudo pide elegir a un mutual y confirmar', (
    tester,
  ) async {
    final economy = FakeEconomyRepository(gems: 0, shields: 2);
    await _pump(
      tester,
      economy,
      mutuals: const [
        MutualCard(mutualId: 1, friend: FakeSocialRepository.luis),
      ],
    );

    await tester.ensureVisible(find.text('Regalar un escudo'));
    await tester.tap(find.text('Regalar un escudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Vega'));
    await tester.pumpAndSettle();
    expect(find.text('¿Regalar un escudo a Luis Vega?'), findsOneWidget);

    await tester.tap(find.text('Regalar').last);
    await tester.pumpAndSettle();
    expect(economy.gifts, [7]);
  });

  testWidgets('sin escudos no se puede regalar', (tester) async {
    await _pump(tester, FakeEconomyRepository(gems: 0, shields: 0));
    await tester.ensureVisible(find.text('Regalar un escudo'));
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Regalar un escudo'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('el historial muestra los movimientos y pagina con "Ver más"', (
    tester,
  ) async {
    final economy = FakeEconomyRepository(
      gems: 45,
      history: [
        fakeTransaction(id: 1, amount: 50),
        fakeTransaction(id: 2, amount: -20, type: WalletTransactionType.spend),
        fakeTransaction(
          id: 3,
          currency: WalletCurrency.shields,
          amount: 1,
          type: WalletTransactionType.giftReceived,
          counterparty: 'luis',
        ),
      ],
    );
    await _pump(tester, economy);

    await tester.scrollUntilVisible(
      find.text('Ver más'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ganaste gemas'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.text('-20'), findsOneWidget);
    expect(find.text('Te regalaron un escudo'), findsNothing);

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Te regalaron un escudo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('@luis · hace 2 h'), findsOneWidget);
    expect(find.text('Ver más'), findsNothing);
  });

  test(
    'el movimiento de escudos se interpreta con la moneda del backend (SHIELD)',
    () {
      final t = WalletTransaction.fromJson({
        'id': 1,
        'currency': 'SHIELD',
        'amount': 1,
        'type': 'GRANT',
        'reason': 'Shield purchase',
        'createdAt': '2026-11-12T01:00:00Z',
      });
      expect(t.currency, WalletCurrency.shields);
      expect(t.currencyEmoji, '🛡️');
      expect(t.title, 'Escudos añadidos');
    },
  );

  test('Wallet calcula cuántos escudos alcanzan', () {
    expect(
      const Wallet(gems: 45, shields: 0, shieldPriceGems: 20).affordableShields,
      2,
    );
    expect(
      const Wallet(gems: 19, shields: 0, shieldPriceGems: 20).affordableShields,
      0,
    );
  });
}
