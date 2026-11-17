import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/media/photo_picker.dart';
import 'package:mutuals/core/network/api_exception.dart';
import 'package:mutuals/features/auth/data/auth_repository.dart';
import 'package:mutuals/features/auth/data/models/user_profile.dart';
import 'package:mutuals/features/moments/data/models/moment_models.dart';
import 'package:mutuals/features/moments/data/moment_repository.dart';
import 'package:mutuals/features/moments/presentation/countdown_ring.dart';
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

  @override
  Future<UserProfile> loginWithGoogle(String idToken) =>
      throw UnimplementedError();

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {}
}

final _detail = StreakDetail(
  id: 9,
  friend: FakeSocialRepository.luis,
  status: StreakStatus.active,
  currentLength: 4,
  startDate: DateTime(2026, 11, 10),
);

const _activeMutual = MutualCard(
  mutualId: 1,
  friend: FakeSocialRepository.luis,
  streak: StreakCard(id: 9, currentLength: 3),
);

Future<void> _pump(
  WidgetTester tester,
  FakeMomentRepository moments, {
  FakePhotoPicker? picker,
}) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
        momentRepositoryProvider.overrideWithValue(moments),
        photoPickerProvider.overrideWithValue(
          picker ??
              FakePhotoPicker(
                '/tmp/galeria.jpg',
                cameraPath: '/tmp/camara.jpg',
              ),
        ),
      ],
      child: const MutualsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre el momento desde el aviso del inicio.
Future<void> _openFromBanner(WidgetTester tester) async {
  await tester.tap(find.textContaining('lanzó un momento'));
  await tester.pumpAndSettle();
}

void main() {
  group('modelo', () {
    test(
      'el tiempo restante cuenta desde que se recibió y nunca es negativo',
      () {
        final received = DateTime(2026, 11, 15, 20);
        final m = Moment(
          id: 1,
          streakId: 1,
          friend: FakeSocialRepository.luis,
          status: MomentStatus.open,
          startedByMe: true,
          startedAt: received,
          expiresAt: received.add(const Duration(minutes: 2)),
          secondsLeft: 100,
          submittedByMe: false,
          friendSubmitted: false,
          photos: const [],
          receivedAt: received,
        );
        expect(m.remainingSeconds(now: received), 100);
        expect(
          m.remainingSeconds(now: received.add(const Duration(seconds: 30))),
          70,
        );
        expect(
          m.remainingSeconds(now: received.add(const Duration(minutes: 5))),
          0,
        );
      },
    );

    test('un momento que ya no está abierto no tiene tiempo restante', () {
      expect(
        fakeMoment(
          status: MomentStatus.expired,
          secondsLeft: 50,
        ).remainingSeconds(),
        0,
      );
      expect(fakeCompletedMoment().remainingSeconds(), 0);
    });

    test(
      'distingue tu foto de la de tu amigo y solo muestra la suya si se reveló',
      () {
        final m = fakeCompletedMoment();
        expect(m.myPhoto?.caption, 'Estudiando');
        expect(m.friendPhoto?.caption, 'Cenando');

        final hidden = fakeMoment(
          photos: [
            fakeMomentPhoto(user: FakeSocialRepository.luis, revealed: false),
          ],
        );
        expect(hidden.friendPhoto, isNull);
      },
    );

    test('formatCountdown escribe minutos y segundos', () {
      expect(formatCountdown(102), '1:42');
      expect(formatCountdown(59), '0:59');
      expect(formatCountdown(0), '0:00');
    });
  });

  testWidgets('sin momentos abiertos el inicio no muestra el aviso', (
    tester,
  ) async {
    await _pump(tester, FakeMomentRepository());
    expect(find.textContaining('lanzó un momento'), findsNothing);
  });

  testWidgets(
    'el inicio avisa del momento que lanzó un amigo y abre la pantalla de la foto',
    (tester) async {
      await _pump(tester, FakeMomentRepository(moments: [fakeMoment()]));
      expect(find.text('¡Luis Vega lanzó un momento!'), findsOneWidget);
      expect(find.text('1:40'), findsOneWidget);

      await _openFromBanner(tester);
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(
        find.textContaining('Esperando la foto de Luis Vega'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tomar la foto, ponerle texto y enviarla lleva a la espera del amigo',
    (tester) async {
      final repo = FakeMomentRepository(moments: [fakeMoment()]);
      await _pump(tester, repo);
      await _openFromBanner(tester);

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();
      expect(find.text('Enviar foto'), findsOneWidget);

      // El pie de foto es opcional y queda más abajo; el botón de enviar siempre está a la vista.
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), 'Estudiando');
      await tester.tap(find.text('Enviar foto'));
      await tester.pumpAndSettle();

      expect(repo.submissions.single.id, 50);
      expect(repo.submissions.single.path, '/tmp/camara.jpg');
      expect(repo.submissions.single.caption, 'Estudiando');
      expect(find.text('¡Tu foto ya salió!'), findsOneWidget);
      expect(find.textContaining('Esperando a Luis Vega'), findsOneWidget);
    },
  );

  testWidgets('sin cámara se ofrece la galería', (tester) async {
    final repo = FakeMomentRepository(moments: [fakeMoment()]);
    await _pump(
      tester,
      repo,
      picker: FakePhotoPicker(
        '/tmp/galeria.jpg',
        cameraError: Exception('sin cámara'),
      ),
    );
    await _openFromBanner(tester);

    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    // Eligió de la galería: ya hay vista previa para enviar.
    expect(find.text('Enviar foto'), findsOneWidget);
    await tester.tap(find.text('Enviar foto'));
    await tester.pumpAndSettle();
    expect(repo.submissions.single.path, '/tmp/galeria.jpg');
  });

  testWidgets('cuando el amigo sube su foto se revelan las dos y se celebra', (
    tester,
  ) async {
    final repo = FakeMomentRepository(moments: [fakeMoment()]);
    await _pump(tester, repo);
    await _openFromBanner(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar foto'));
    await tester.pumpAndSettle();
    expect(find.text('¡Tu foto ya salió!'), findsOneWidget);

    // El amigo sube la suya; la pantalla lo detecta sola.
    repo.friendSubmits(50);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('¡Momento completado!'), findsOneWidget);
    expect(find.text('Estudiando'), findsOneWidget);
    expect(find.text('Cenando'), findsOneWidget);
    expect(find.text('Tú'), findsOneWidget);
    expect(find.text('Luis Vega'), findsWidgets);
    expect(find.text('4'), findsOneWidget); // días de racha
  });

  testWidgets('si se acaba el tiempo se muestra y no se puede subir', (
    tester,
  ) async {
    final repo = FakeMomentRepository(moments: [fakeMoment()]);
    await _pump(tester, repo);
    await _openFromBanner(tester);
    expect(find.text('Tomar foto'), findsOneWidget);

    repo.expire(50);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Se acabó el tiempo'), findsOneWidget);
    expect(find.text('Tomar foto'), findsNothing);
  });

  testWidgets('un error al subir se muestra en pantalla', (tester) async {
    final repo = _FailingSubmit(moments: [fakeMoment()]);
    await _pump(tester, repo);
    await _openFromBanner(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar foto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solo se permiten imágenes JPEG, PNG o WEBP'),
      findsOneWidget,
    );
    expect(find.text('Enviar foto'), findsOneWidget); // puede intentar de nuevo
  });

  testWidgets(
    'también se puede elegir la foto de la galería, sin abrir la cámara',
    (tester) async {
      final repo = FakeMomentRepository(moments: [fakeMoment()]);
      await _pump(
        tester,
        repo,
        picker: FakePhotoPicker(
          '/tmp/galeria.jpg',
          cameraPath: '/tmp/camara.jpg',
        ),
      );
      await _openFromBanner(tester);

      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar foto'));
      await tester.pumpAndSettle();
      expect(repo.submissions.single.path, '/tmp/galeria.jpg');
    },
  );

  group('lanzar un momento desde Registrar hoy', () {
    Future<void> openCheckIn(WidgetTester tester) async {
      await tester.tap(find.text('Luis Vega'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar hoy'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide confirmación, lanza el momento y abre la pantalla', (
      tester,
    ) async {
      final repo = FakeMomentRepository();
      await _pump(tester, repo);
      await openCheckIn(tester);

      await tester.tap(find.text('Momento de foto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Lanzar un momento a Luis Vega?'), findsOneWidget);

      await tester.tap(find.text('¡Lanzar!'));
      await tester.pumpAndSettle();
      expect(repo.started, [7]);
      expect(find.text('¡Sube tu foto!'), findsOneWidget);
    });

    testWidgets(
      'si ya había uno abierto con esa persona lo abre en vez de crear otro',
      (tester) async {
        final repo = FakeMomentRepository(
          moments: [fakeMoment(id: 31, startedByMe: true)],
          startError: const ApiException(
            message: 'There is already an open moment with this friend',
            statusCode: 409,
          ),
        );
        await _pump(tester, repo);
        await openCheckIn(tester);

        await tester.tap(find.text('Momento de foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('¡Lanzar!'));
        await tester.pumpAndSettle();
        expect(find.text('¡Sube tu foto!'), findsOneWidget);
        expect(find.text('Tomar foto'), findsOneWidget);
      },
    );

    testWidgets('cancelar no lanza nada', (tester) async {
      final repo = FakeMomentRepository();
      await _pump(tester, repo);
      await openCheckIn(tester);
      await tester.tap(find.text('Momento de foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(repo.started, isEmpty);
    });
  });

  group('recuerdos', () {
    Future<void> openMemories(WidgetTester tester) async {
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Recuerdos'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Recuerdos'));
      await tester.pumpAndSettle();
    }

    testWidgets('sin momentos completados se explica cómo llegan', (
      tester,
    ) async {
      await _pump(tester, FakeMomentRepository());
      await openMemories(tester);
      expect(find.text('Aún no tienes recuerdos'), findsOneWidget);
    });

    testWidgets('muestra cada momento completado y lo abre con las dos fotos', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeMomentRepository(
          moments: [fakeCompletedMoment()],
          historyItems: [fakeCompletedMoment()],
        ),
      );
      await openMemories(tester);
      expect(find.text('Con Luis Vega'), findsOneWidget);

      await tester.tap(find.text('Con Luis Vega'));
      await tester.pumpAndSettle();
      expect(find.text('¡Momento completado!'), findsOneWidget);
    });
  });
}

class _FailingSubmit extends FakeMomentRepository {
  _FailingSubmit({super.moments});

  @override
  Future<Moment> submitPhoto(
    int id,
    String photoPath, {
    String? caption,
  }) async => throw const ApiException(
    message: 'Solo se permiten imágenes JPEG, PNG o WEBP',
    statusCode: 400,
  );
}
