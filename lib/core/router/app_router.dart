import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/data/models/activity_models.dart';
import '../../features/activity/presentation/comments_page.dart';
import '../../features/activity/presentation/feed_page.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/interactions/presentation/timeline_page.dart';
import '../../features/social/presentation/customization_page.dart';
import '../../features/social/presentation/user_list_page.dart';
import '../../features/economy/presentation/wallet_page.dart';
import '../../features/subscription/presentation/plus_page.dart';
import '../../features/wrapped/data/models/wrapped_models.dart';
import '../../features/wrapped/presentation/wrapped_page.dart';
import '../../features/gamification/presentation/achievements_page.dart';
import '../../features/gamification/presentation/avatar_page.dart';
import '../../features/gamification/presentation/challenges_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/interactions/presentation/check_in_page.dart';
import '../../features/interactions/presentation/my_qr_page.dart';
import '../../features/interactions/presentation/pending_page.dart';
import '../../features/interactions/presentation/scan_qr_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/social/data/models/social_models.dart';
import '../../features/social/presentation/edit_profile_page.dart';
import '../../features/social/presentation/mutuals_page.dart';
import '../../features/social/presentation/my_profile_page.dart';
import '../../features/social/presentation/profile_page.dart';
import '../../features/social/presentation/search_page.dart';
import '../../features/social/presentation/settings_page.dart';
import '../../features/streaks/presentation/history_page.dart';
import '../../features/streaks/presentation/invitations_page.dart';
import '../../features/streaks/presentation/streak_detail_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/moments/presentation/memories_page.dart';
import '../../features/moments/presentation/moment_page.dart';

/// Página que sube desde abajo a pantalla completa (QR, escáner, historias).
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondary, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween(begin: 0.6, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/';
  static const mutuals = '/mutuals';
  static const feed = '/feed';
  static const search = '/search';
  static const me = '/me';

  static const _public = {login, register, forgotPassword, resetPassword};
}

/// Avisa al router cuando cambia el estado de la sesión.
class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(
    authControllerProvider.select((s) => s.status),
    (_, _) => refresh.ping(),
  );

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
          final inAuthFlow =
              path == Routes.splash || Routes._public.contains(path);
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
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.mutuals,
                builder: (_, _) => const MutualsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.feed, builder: (_, _) => const FeedPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.search,
                builder: (_, _) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.me,
                builder: (_, _) => const MyProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/activities/:id/comments',
        builder: (_, state) => CommentsPage(activity: state.extra! as Activity),
      ),
      GoRoute(path: '/wrapped', builder: (_, _) => const WrappedPage()),
      GoRoute(
        path: '/wrapped/all-time',
        pageBuilder: (_, state) => _slideUp(state, const AllTimeWrappedPage()),
      ),
      GoRoute(
        path: '/wrapped/story',
        pageBuilder: (_, state) => _slideUp(
          state,
          PeriodWrappedPage(summary: state.extra! as WrappedSummary),
        ),
      ),
      GoRoute(path: '/plus', builder: (_, _) => const PlusPage()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(path: '/wallet', builder: (_, _) => const WalletPage()),
      GoRoute(
        path: '/achievements',
        builder: (_, _) => const AchievementsPage(),
      ),
      GoRoute(path: '/avatar', builder: (_, _) => const AvatarPage()),
      GoRoute(path: '/challenges', builder: (_, _) => const ChallengesPage()),
      GoRoute(
        path: '/challenges/:id',
        builder: (_, state) => ChallengeDetailPage(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/moments', builder: (_, _) => const MemoriesPage()),
      GoRoute(
        path: '/moments/:id',
        pageBuilder: (_, state) => _slideUp(
          state,
          MomentPage(momentId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/qr',
        pageBuilder: (_, state) => _slideUp(state, const MyQrPage()),
      ),
      GoRoute(
        path: '/scan',
        pageBuilder: (_, state) => _slideUp(state, const ScanQrPage()),
      ),
      GoRoute(
        path: '/pending',
        builder: (_, _) => const PendingInteractionsPage(),
      ),
      GoRoute(
        path: '/check-in',
        pageBuilder: (_, state) =>
            _slideUp(state, CheckInPage(friend: state.extra! as UserSummary)),
      ),
      GoRoute(path: '/invitations', builder: (_, _) => const InvitationsPage()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
      GoRoute(
        path: '/streaks/:id',
        builder: (_, state) =>
            StreakDetailPage(streakId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/timeline', builder: (_, _) => const TimelinePage()),
      GoRoute(
        path: '/customization',
        builder: (_, _) => const CustomizationPage(),
      ),
      GoRoute(path: '/blocked', builder: (_, _) => const BlockedUsersPage()),
      GoRoute(
        path: '/users/:id/followers',
        builder: (_, state) => FollowListPage(
          userId: int.parse(state.pathParameters['id']!),
          followers: true,
        ),
      ),
      GoRoute(
        path: '/users/:id/following',
        builder: (_, state) => FollowListPage(
          userId: int.parse(state.pathParameters['id']!),
          followers: false,
        ),
      ),
      GoRoute(
        path: '/users/:id',
        builder: (_, state) =>
            ProfilePage(userId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});
