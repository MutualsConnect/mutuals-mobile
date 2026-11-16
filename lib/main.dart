import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/glass.dart';

void main() {
  runApp(const ProviderScope(child: MutualsApp()));
}

/// Desplazamiento con rebote, como en iOS, también en Android: se siente más fluido.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class MutualsApp extends ConsumerWidget {
  const MutualsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mutuals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Mutuals es oscuro con vidrio, sin importar el modo del sistema.
      themeMode: ThemeMode.dark,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          AmbientBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
