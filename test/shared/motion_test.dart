import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/shared/motion/animated_count.dart';
import 'package:mutuals/shared/motion/animated_flame.dart';
import 'package:mutuals/shared/motion/confetti.dart';
import 'package:mutuals/shared/motion/fade_slide_in.dart';
import 'package:mutuals/shared/motion/heart_pop.dart';
import 'package:mutuals/shared/motion/press_scale.dart';
import 'package:mutuals/shared/motion/skeleton.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FadeSlideIn', () {
    testWidgets('el contenido arranca transparente y termina visible', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const FadeSlideIn(child: Text('Hola'))));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      expect(find.text('Hola'), findsOneWidget);
    });

    testWidgets('con un índice mayor tarda más en aparecer', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              FadeSlideIn(index: 0, child: Text('A')),
              FadeSlideIn(index: 5, child: Text('B')),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities[0], greaterThan(opacities[1]));
      await tester.pumpAndSettle();
    });
  });

  group('PressScale', () {
    testWidgets('se encoge al mantener presionado y vuelve al soltar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const PressScale(child: SizedBox(width: 100, height: 100))),
      );
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('no impide que el botón de adentro reciba el toque', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          PressScale(
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('Ir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ir'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  testWidgets('AnimatedCount sube hasta el valor final', (tester) async {
    await tester.pumpWidget(
      _host(const AnimatedCount(value: 42, prefix: '🔥 ')),
    );
    expect(find.text('🔥 0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('🔥 42'), findsOneWidget);
  });

  group('HeartPop', () {
    testWidgets('cambia de corazón vacío a lleno al dar me gusta', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const HeartPop(liked: false)));
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.pumpWidget(_host(const HeartPop(liked: true)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      // En pleno rebote es más grande que su tamaño normal.
      final pop = find.descendant(
        of: find.byType(HeartPop),
        matching: find.byType(ScaleTransition),
      );
      expect(
        tester.widgetList<ScaleTransition>(pop).first.scale.value,
        greaterThan(1),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('el corazón grande aparece con el disparador y se desvanece', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const BigHeartOverlay(trigger: 0)));
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);

      await tester.pumpWidget(_host(const BigHeartOverlay(trigger: 1)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });
  });

  group('SkeletonCards', () {
    testWidgets('muestra todas las tarjetas si hay espacio', (tester) async {
      await tester.pumpWidget(
        _host(
          const SingleChildScrollView(
            child: SkeletonCards(count: 3, height: 80),
          ),
        ),
      );
      expect(find.byType(SkeletonBox), findsNWidgets(3));
    });

    testWidgets(
      'en un espacio bajo solo muestra las que caben, sin desbordar',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              height: 260,
              child: SkeletonCards(count: 6, height: 100),
            ),
          ),
        );
        expect(
          find.byType(SkeletonBox),
          findsNWidgets(2),
        ); // 260 - 40 de margen = 220 → 2 de 112
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('el confeti se dibuja y termina sin dejar animaciones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const SizedBox(width: 300, height: 300, child: ConfettiBurst())),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ConfettiBurst), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('la llama late unas veces y se queda quieta', (tester) async {
    await tester.pumpWidget(_host(const AnimatedFlame(pulses: 2)));
    await tester.pumpAndSettle(); // si fuera infinita esto no terminaría
    expect(find.text('🔥'), findsOneWidget);
  });
}
