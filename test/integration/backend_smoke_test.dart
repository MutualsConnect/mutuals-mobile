// Prueba contra el backend real (localhost:8080). Se omite por defecto.
//
//   MUTUALS_E2E=1 flutter test test/integration/backend_smoke_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/network/api_client.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/core/storage/token_storage.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/activity/data/activity_repository.dart';
import 'package:mutuals/features/economy/data/economy_repository.dart';
import 'package:mutuals/features/economy/data/models/economy_models.dart';
import 'package:mutuals/features/gamification/data/gamification_repository.dart';
import 'package:mutuals/features/gamification/data/models/gamification_models.dart';
import 'package:mutuals/features/interactions/data/interaction_repository.dart';
import 'package:mutuals/features/interactions/data/models/interaction_models.dart';
import 'package:mutuals/features/notifications/data/models/notification_models.dart';
import 'package:mutuals/features/notifications/data/notification_repository.dart';
import 'package:mutuals/features/social/data/social_repository.dart';
import 'package:mutuals/features/streaks/data/models/streak_models.dart';
import 'package:mutuals/features/streaks/data/streak_repository.dart';

void main() {
  final enabled = Platform.environment.containsKey('MUTUALS_E2E');

  group(
    'backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      late InMemoryTokenStorage tokens;
      late AuthRepository repo;

      setUp(() {
        tokens = InMemoryTokenStorage();
        final dio = createApiClient(
          tokens: tokens,
          onSessionExpired: () {},
          baseUrl: 'http://localhost:8080/api/v1',
        );
        repo = AuthRepository(dio, tokens);
      });

      test('registro, restaurar sesión y cerrar sesión', () async {
        final id = DateTime.now().millisecondsSinceEpoch;
        final user = await repo.register(
          email: 'e2e$id@example.com',
          username: 'e2e$id',
          displayName: 'E2E Test',
          password: 'Prueba!2026x',
        );
        expect(user.username, 'e2e$id');
        expect(await tokens.readRefreshToken(), isNotNull);

        final restored = await repo.restoreSession();
        expect(restored?.email, 'e2e$id@example.com');

        await repo.logout();
        expect(await tokens.readRefreshToken(), isNull);
        expect(await repo.restoreSession(), isNull);
      });

      test(
        'login con credenciales incorrectas lanza ApiException 401',
        () async {
          await expectLater(
            repo.login(email: 'nadie@example.com', password: 'Mala!2026x'),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', 401),
            ),
          );
        },
      );

      test('registro con datos inválidos devuelve errores por campo', () async {
        try {
          await repo.register(
            email: 'mal',
            username: 'X',
            displayName: '',
            password: '123',
          );
          fail('debió lanzar');
        } on ApiException catch (e) {
          expect(e.statusCode, 400);
          expect(
            e.fieldErrors.keys,
            containsAll(['email', 'username', 'password']),
          );
        }
      });

      test('el correo repetido se rechaza', () async {
        await expectLater(
          repo.register(
            email: 'ashly.test@example.com',
            username: 'otro.usuario',
            displayName: 'Otro',
            password: 'Prueba!2026x',
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 409),
          ),
        );
      });
    },
  );

  group(
    'social en el backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      Future<(SocialRepository, int, String)> newUser(String tag) async {
        final tokens = InMemoryTokenStorage();
        final dio = createApiClient(
          tokens: tokens,
          onSessionExpired: () {},
          baseUrl: 'http://localhost:8080/api/v1',
        );
        final id = DateTime.now().microsecondsSinceEpoch;
        final user = await AuthRepository(dio, tokens).register(
          email: '$tag$id@example.com',
          username: '$tag$id',
          displayName: 'User $tag',
          password: 'Prueba!2026x',
        );
        return (SocialRepository(dio), user.id, user.username);
      }

      test(
        'seguirse mutuamente crea un mutual y aparece en la lista',
        () async {
          final (ana, anaId, anaName) = await newUser('ana');
          final (luis, luisId, _) = await newUser('luis');

          final found = await ana.search(anaName.substring(0, 6));
          expect(found.content.any((u) => u.id == anaId), isTrue);

          final first = await ana.follow(luisId);
          expect(first.following, isTrue);
          expect(first.mutual, isFalse);

          final back = await luis.follow(anaId);
          expect(back.mutual, isTrue);

          final profile = await ana.profile(luisId);
          expect(profile.isMutual, isTrue);

          final mutuals = await ana.mutuals();
          expect(mutuals.single.friend.id, luisId);

          await ana.unfollow(luisId);
          expect((await ana.profile(luisId)).followedByMe, isFalse);
        },
      );
    },
  );

  group(
    'rachas en el backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      Future<(SocialRepository, StreakRepository, int)> newUser(
        String tag,
      ) async {
        final tokens = InMemoryTokenStorage();
        final dio = createApiClient(
          tokens: tokens,
          onSessionExpired: () {},
          baseUrl: 'http://localhost:8080/api/v1',
        );
        final id = DateTime.now().microsecondsSinceEpoch;
        final user = await AuthRepository(dio, tokens).register(
          email: '$tag$id@example.com',
          username: '$tag$id',
          displayName: 'User $tag',
          password: 'Prueba!2026x',
        );
        return (SocialRepository(dio), StreakRepository(dio), user.id);
      }

      test('invitar, aceptar y ver la racha activa', () async {
        final (anaSocial, anaStreaks, anaId) = await newUser('rana');
        final (luisSocial, luisStreaks, luisId) = await newUser('rluis');
        await anaSocial.follow(luisId);
        await luisSocial.follow(anaId);

        final invitation = await anaStreaks.invite(luisId);
        expect(invitation.status, InvitationStatus.pending);
        expect(
          (await anaStreaks.invitations(InvitationBox.sent)).single.id,
          invitation.id,
        );

        final received = await luisStreaks.invitations(InvitationBox.received);
        expect(received.single.inviter.id, anaId);

        final accepted = await luisStreaks.respond(
          received.single.id,
          accept: true,
        );
        expect(accepted.status, InvitationStatus.accepted);

        final card = (await anaSocial.mutuals()).single;
        expect(card.streak, isNotNull);

        final detail = await anaStreaks.detail(card.streak!.id);
        expect(detail.isActive, isTrue);
        expect(detail.friend.id, luisId);

        final history = await anaStreaks.history();
        expect(history.single.streaks.single.id, detail.id);
      });

      test('no se puede invitar a quien no es mutual', () async {
        final (_, anaStreaks, _) = await newUser('sana');
        final (_, _, luisId) = await newUser('sluis');
        await expectLater(
          anaStreaks.invite(luisId),
          throwsA(isA<ApiException>()),
        );
      });
    },
  );

  group(
    'interacciones en el backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      /// Dos usuarios que ya son mutuals y tienen una racha activa.
      Future<(InteractionRepository, InteractionRepository, int, int)>
      activePair(String tag) async {
        Future<(SocialRepository, StreakRepository, InteractionRepository, int)>
        user(String name) async {
          final tokens = InMemoryTokenStorage();
          final dio = createApiClient(
            tokens: tokens,
            onSessionExpired: () {},
            baseUrl: 'http://localhost:8080/api/v1',
          );
          final id = DateTime.now().microsecondsSinceEpoch;
          final u = await AuthRepository(dio, tokens).register(
            email: '$name$id@example.com',
            username: '$name$id',
            displayName: 'User $name',
            password: 'Prueba!2026x',
          );
          return (
            SocialRepository(dio),
            StreakRepository(dio),
            InteractionRepository(dio),
            u.id,
          );
        }

        final (aSocial, aStreaks, aInter, aId) = await user('${tag}a');
        final (bSocial, bStreaks, bInter, bId) = await user('${tag}b');
        await aSocial.follow(bId);
        await bSocial.follow(aId);
        await aStreaks.invite(bId);
        final inv = (await bStreaks.invitations(InvitationBox.received)).single;
        await bStreaks.respond(inv.id, accept: true);
        return (aInter, bInter, aId, bId);
      }

      test('confirmación manual: uno registra y el otro confirma', () async {
        final (ana, luis, _, luisId) = await activePair('m');
        final created = await ana.create(luisId, note: 'Café');
        expect(created.status, InteractionStatus.pending);

        final pending = await luis.pending();
        expect(pending.single.id, created.id);
        expect(pending.single.note, 'Café');

        final confirmed = await luis.confirm(created.id);
        expect(confirmed.status, InteractionStatus.confirmed);
        expect(confirmed.streakLength, 1);
        expect(await luis.pending(), isEmpty);
      });

      test('rechazar una interacción', () async {
        final (ana, luis, _, luisId) = await activePair('r');
        final created = await ana.create(luisId);
        final rejected = await luis.reject(created.id);
        expect(rejected.status, InteractionStatus.rejected);
      });

      test('QR: escanear el código de un amigo confirma al instante', () async {
        final (ana, luis, _, _) = await activePair('q');
        final qr = await ana.myQr();
        expect(qr.token, isNotEmpty);
        expect(
          qr.expiresAt.isAfter(
            DateTime.now().subtract(const Duration(seconds: 5)),
          ),
          isTrue,
        );

        final result = await luis.checkInWithQr(qr.token);
        expect(result.status, InteractionStatus.confirmed);
        expect(result.streakLength, 1);
      });

      test('QR: un código inventado se rechaza', () async {
        final (_, luis, _, _) = await activePair('x');
        await expectLater(
          luis.checkInWithQr('codigo-falso'),
          throwsA(isA<ApiException>()),
        );
      });

      test('proximidad: ambos envían su ubicación y se confirma', () async {
        final (ana, luis, anaId, luisId) = await activePair('p');
        final first = await ana.checkInByProximity(
          friendId: luisId,
          latitude: -12.0464,
          longitude: -77.0428,
        );
        expect(first.confirmed, isFalse);

        final second = await luis.checkInByProximity(
          friendId: anaId,
          latitude: -12.0464,
          longitude: -77.0428,
        );
        expect(second.confirmed, isTrue);
        expect(second.interaction?.streakLength, 1);
      });
    },
  );

  group(
    'notificaciones en el backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      /// Los avisos se crean en segundo plano; esperamos a que lleguen.
      Future<List<AppNotification>> waitFor(
        NotificationRepository repo,
        bool Function(List<AppNotification>) ok,
      ) async {
        for (var i = 0; i < 20; i++) {
          final page = (await repo.list()).content;
          if (ok(page)) return page;
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        fail('Las notificaciones no llegaron a tiempo');
      }

      test('seguir e invitar generan avisos que se pueden leer', () async {
        Future<
          (SocialRepository, StreakRepository, NotificationRepository, int)
        >
        user(String name) async {
          final tokens = InMemoryTokenStorage();
          final dio = createApiClient(
            tokens: tokens,
            onSessionExpired: () {},
            baseUrl: 'http://localhost:8080/api/v1',
          );
          final id = DateTime.now().microsecondsSinceEpoch;
          final u = await AuthRepository(dio, tokens).register(
            email: '$name$id@example.com',
            username: '$name$id',
            displayName: 'User $name',
            password: 'Prueba!2026x',
          );
          return (
            SocialRepository(dio),
            StreakRepository(dio),
            NotificationRepository(dio),
            u.id,
          );
        }

        final (aSocial, aStreaks, _, aId) = await user('na');
        final (bSocial, _, bNotes, bId) = await user('nb');

        await aSocial.follow(bId);
        await bSocial.follow(aId);
        await aStreaks.invite(bId);

        final list = await waitFor(
          bNotes,
          (l) => l.any((n) => n.type == 'STREAK_INVITATION'),
        );
        final invitation = list.firstWhere(
          (n) => n.type == 'STREAK_INVITATION',
        );
        expect(invitation.read, isFalse);
        expect(invitation.priority, NotificationPriority.high);
        expect(invitation.route, '/invitations');
        expect(
          list.any((n) => n.type == 'NEW_FOLLOWER' && n.route == '/users/$aId'),
          isTrue,
        );

        final before = (await bNotes.unreadCount()).total;
        expect(before, greaterThanOrEqualTo(2));

        await bNotes.markRead(invitation.id);
        expect((await bNotes.unreadCount()).total, before - 1);

        final important = (await bNotes.list(
          priority: NotificationPriority.high,
        )).content;
        expect(
          important.every((n) => n.priority == NotificationPriority.high),
          isTrue,
        );

        await bNotes.markAllRead();
        expect((await bNotes.unreadCount()).total, 0);
      });
    },
  );

  group(
    'economía en el backend real',
    skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar',
    () {
      /// Las gemas se ganan con semanas de racha; para probar le damos gemas a mano
      /// en la base de datos local (contenedor de docker-compose).
      Future<void> grantGems(int userId, int gems) async {
        final result = await Process.run('docker', [
          'exec',
          'mutuals-backend-db-1',
          'psql',
          '-U',
          'mutuals',
          '-d',
          'mutuals',
          '-c',
          'update users set gems = $gems where id = $userId',
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      }

      Future<(EconomyRepository, SocialRepository, int)> user(
        String name,
      ) async {
        final tokens = InMemoryTokenStorage();
        final dio = createApiClient(
          tokens: tokens,
          onSessionExpired: () {},
          baseUrl: 'http://localhost:8080/api/v1',
        );
        final id = DateTime.now().microsecondsSinceEpoch;
        final u = await AuthRepository(dio, tokens).register(
          email: '$name$id@example.com',
          username: '$name$id',
          displayName: 'User $name',
          password: 'Prueba!2026x',
        );
        return (EconomyRepository(dio), SocialRepository(dio), u.id);
      }

      test('una cuenta nueva empieza sin gemas ni escudos', () async {
        final (economy, _, _) = await user('w0');
        final wallet = await economy.wallet();
        expect(wallet.gems, 0);
        expect(wallet.shields, 0);
        expect(wallet.shieldPriceGems, greaterThan(0));
        expect((await economy.transactions()).content, isEmpty);
      });

      test('comprar escudos descuenta gemas y queda en el historial', () async {
        final (economy, _, id) = await user('w1');
        final price = (await economy.wallet()).shieldPriceGems;
        await grantGems(id, price * 3);

        final after = await economy.purchaseShields(2);
        expect(after.shields, 2);
        expect(after.gems, price);

        final history = (await economy.transactions()).content;
        expect(
          history.any(
            (t) => t.type == WalletTransactionType.spend && t.amount < 0,
          ),
          isTrue,
        );
      });

      test('sin gemas suficientes la compra se rechaza', () async {
        final (economy, _, _) = await user('w2');
        await expectLater(
          economy.purchaseShields(1),
          throwsA(isA<ApiException>()),
        );
      });

      test('regalar un escudo a un mutual', () async {
        final (aEconomy, aSocial, aId) = await user('w3a');
        final (bEconomy, bSocial, bId) = await user('w3b');
        final price = (await aEconomy.wallet()).shieldPriceGems;
        await grantGems(aId, price);
        await aEconomy.purchaseShields(1);
        await aSocial.follow(bId);
        await bSocial.follow(aId);

        final after = await aEconomy.giftShield(bId);
        expect(after.shields, 0);
        expect((await bEconomy.wallet()).shields, 1);
        final received = (await bEconomy.transactions()).content;
        expect(
          received.any((t) => t.type == WalletTransactionType.giftReceived),
          isTrue,
        );
      });
    },
  );

  group('gamificación en el backend real', skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar', () {
    Future<String> sql(String query) async {
      final result = await Process.run('docker', [
        'exec',
        'mutuals-backend-db-1',
        'psql',
        '-U',
        'mutuals',
        '-d',
        'mutuals',
        '-t',
        '-A',
        '-c',
        query,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      return (result.stdout as String).trim().split('\n').first.trim();
    }

    Future<
      ({
        GamificationRepository gami,
        EconomyRepository economy,
        SocialRepository social,
        StreakRepository streaks,
        int id,
      })
    >
    user(String name) async {
      final tokens = InMemoryTokenStorage();
      final dio = createApiClient(
        tokens: tokens,
        onSessionExpired: () {},
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final id = DateTime.now().microsecondsSinceEpoch;
      final u = await AuthRepository(dio, tokens).register(
        email: '$name$id@example.com',
        username: '$name$id',
        displayName: 'User $name',
        password: 'Prueba!2026x',
      );
      return (
        gami: GamificationRepository(dio),
        economy: EconomyRepository(dio),
        social: SocialRepository(dio),
        streaks: StreakRepository(dio),
        id: u.id,
      );
    }

    test(
      'el catálogo de logros llega y una cuenta nueva no tiene ninguno',
      () async {
        final u = await user('g1');
        final list = await u.gami.achievements();
        expect(list, isNotEmpty);
        expect(list.any((a) => a.code == 'FIRST_STREAK_DAY'), isTrue);
        expect(list.every((a) => !a.unlocked), isTrue);
      },
    );

    test('avatar: comprar con gemas, equipar y ver el estado', () async {
      final u = await user('g2');
      final items = await u.gami.avatarItems();
      final hair = items.firstWhere((i) => i.code == 'HAIR_CURLY');
      expect(hair.owned, isFalse);
      await expectLater(
        u.gami.purchaseAvatarItem(hair.id),
        throwsA(isA<ApiException>()),
      );

      await Process.run('docker', [
        'exec',
        'mutuals-backend-db-1',
        'psql',
        '-U',
        'mutuals',
        '-d',
        'mutuals',
        '-c',
        'update users set gems = 100 where id = ${u.id}',
      ]);
      final bought = await u.gami.purchaseAvatarItem(hair.id);
      expect(bought.owned, isTrue);
      expect((await u.economy.wallet()).gems, 100 - hair.priceGems);

      await u.gami.equipAvatarItem(hair.id);
      final after = await u.gami.avatarItems();
      expect(after.firstWhere((i) => i.id == hair.id).equipped, isTrue);
    });

    test('desafío semanal: ambos cumplen, se completa y ganan gemas', () async {
      final a = await user('g3a');
      final b = await user('g3b');
      await a.social.follow(b.id);
      await b.social.follow(a.id);

      final mutualId = await sql(
        'select id from mutuals where (user_a_id = ${a.id} and user_b_id = ${b.id}) or (user_a_id = ${b.id} and user_b_id = ${a.id})',
      );
      // El desafío se asigna cada lunes; aquí lo creamos para esta semana (hora de Lima).
      final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
      final monday = lima.subtract(Duration(days: lima.weekday - 1));
      final weekStart =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      await sql(
        "insert into challenges (created_at, updated_at, status, week_start, mutual_id, template_id) values (now(), now(), 'OPEN', '$weekStart', $mutualId, 1)",
      );

      final mine = await a.gami.challenges();
      expect(mine.single.status, ChallengeStatus.open);
      expect(mine.single.submittedByMe, isFalse);
      final id = mine.single.id;

      final first = await a.gami.submitChallenge(
        id,
        content: '¿Cuál es tu comida favorita?',
      );
      expect(first.submittedByMe, isTrue);
      expect(first.status, ChallengeStatus.open);

      final second = await b.gami.submitChallenge(id, content: 'El ceviche');
      expect(second.status, ChallengeStatus.completed);

      final reward = mine.single.template.rewardGems;
      // Además del premio del desafío, completarlo puede desbloquear un logro con gemas.
      // El logro se concede en segundo plano, igual que las notificaciones.
      var unlocked = <Achievement>[];
      for (var i = 0; i < 20 && unlocked.isEmpty; i++) {
        unlocked = (await a.gami.achievements())
            .where((x) => x.unlocked)
            .toList();
        if (unlocked.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }
      expect(unlocked, isNotEmpty);
      final bonus = unlocked.fold<int>(0, (sum, x) => sum + x.rewardGems);
      expect((await a.economy.wallet()).gems, reward + bonus);
      expect((await b.economy.wallet()).gems, greaterThanOrEqualTo(reward));

      final revealed = await a.gami.challenge(id);
      expect(revealed.submissions.every((s) => s.revealed), isTrue);
      expect(
        revealed.submissions.map((s) => s.content),
        contains('El ceviche'),
      );
    });
  });

  group('feed en el backend real', skip: enabled ? false : 'Define MUTUALS_E2E=1 para ejecutar', () {
    Future<(ActivityRepository, SocialRepository, int)> user(
      String name,
    ) async {
      final tokens = InMemoryTokenStorage();
      final dio = createApiClient(
        tokens: tokens,
        onSessionExpired: () {},
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final id = DateTime.now().microsecondsSinceEpoch;
      final u = await AuthRepository(dio, tokens).register(
        email: '$name$id@example.com',
        username: '$name$id',
        displayName: 'User $name',
        password: 'Prueba!2026x',
      );
      return (ActivityRepository(dio), SocialRepository(dio), u.id);
    }

    test('likes y comentarios: los mutuals pueden, quien solo sigue no', () async {
      final (aFeed, aSocial, aId) = await user('f1a');
      final (bFeed, bSocial, bId) = await user('f1b');
      final (cFeed, cSocial, _) = await user('f1c');

      // a y b son mutuals; c solo sigue a b.
      await aSocial.follow(bId);
      await bSocial.follow(aId);
      await cSocial.follow(bId);

      // Las novedades las crea el backend con hitos y logros; aquí insertamos una de b.
      final inserted = await Process.run('docker', [
        'exec',
        'mutuals-backend-db-1',
        'psql',
        '-U',
        'mutuals',
        '-d',
        'mutuals',
        '-t',
        '-A',
        '-c',
        "insert into activities (created_at, updated_at, comment_count, like_count, title, type, metric_value, actor_id) "
            "values (now(), now(), 0, 0, 'User f1b llegó a 7 días de racha', 'STREAK_MILESTONE', 7, $bId) returning id",
      ]);
      expect(inserted.exitCode, 0, reason: '${inserted.stderr}');
      final activityId = int.parse(
        (inserted.stdout as String).trim().split('\n').first,
      );

      // a (mutual) la ve con permiso para comentar.
      final seenByA = (await aFeed.feed()).content.firstWhere(
        (x) => x.id == activityId,
      );
      expect(seenByA.fromMutual, isTrue);
      expect(seenByA.canComment, isTrue);
      expect(seenByA.likedByMe, isFalse);

      // like y unlike.
      await aFeed.like(activityId);
      expect(
        (await aFeed.feed()).content
            .firstWhere((x) => x.id == activityId)
            .likedByMe,
        isTrue,
      );
      await aFeed.unlike(activityId);
      expect(
        (await aFeed.feed()).content
            .firstWhere((x) => x.id == activityId)
            .likedByMe,
        isFalse,
      );

      // comentar.
      final comment = await aFeed.comment(activityId, '¡Qué racha!');
      expect(comment.content, '¡Qué racha!');
      final comments = (await bFeed.comments(activityId)).content;
      expect(comments.single.content, '¡Qué racha!');
      expect(
        (await bFeed.feed()).content
            .firstWhere((x) => x.id == activityId)
            .commentCount,
        1,
      );

      // c ve la novedad pero no puede comentar.
      final seenByC = (await cFeed.feed()).content.firstWhere(
        (x) => x.id == activityId,
      );
      expect(seenByC.fromMutual, isFalse);
      expect(seenByC.canComment, isFalse);
      await expectLater(
        cFeed.comment(activityId, 'Hola'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
