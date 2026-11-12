import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MutualsApp()));
}

class MutualsApp extends ConsumerWidget {
  const MutualsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mutuals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // El diseño de Mutuals es claro y cálido; no seguimos el modo oscuro del sistema.
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
