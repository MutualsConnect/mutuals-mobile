import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/social/presentation/mutuals_page.dart';
import '../../features/social/presentation/my_profile_page.dart';
import '../../features/social/presentation/profile_page.dart';
import '../../features/social/presentation/search_page.dart';
import '../../features/splash/presentation/splash_page.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const mutuals = '/mutuals';
  static const search = '/search';
  static const me = '/me';

  static const _public = {login, register, forgotPassword};
}

/// Avisa al router cuando cambia el estado de la sesión.
class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider.select((s) => s.status), (_, _) => refresh.ping());

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final path = state.matchedLocation;
      switch (status) {
        case AuthStatus.unknown:
          return path == Routes.splash ? null : Routes.splash;
        case AuthStatus.unauthenticated:
          return Routes._public.contains(path) ? null : Routes.login;
        case AuthStatus.authenticated:
          final inAuthFlow = path == Routes.splash || Routes._public.contains(path);
          return inAuthFlow ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.mutuals, builder: (_, _) => const MutualsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, builder: (_, _) => const SearchPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.me, builder: (_, _) => const MyProfilePage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) => ProfilePage(userId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
