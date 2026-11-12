import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/main.dart';

void main() {
  testWidgets('La app abre en la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MutualsApp()));
    await tester.pumpAndSettle();

    expect(find.text('Mutuals'), findsOneWidget);
    expect(find.text('Tus rachas'), findsOneWidget);
  });
}
