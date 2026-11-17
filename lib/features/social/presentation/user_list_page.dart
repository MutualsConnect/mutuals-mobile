import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/page_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/motion/skeleton.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/icon_text.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../data/models/social_models.dart';
import '../data/profile_repository.dart';
import '../data/social_repository.dart';

/// Lista de personas: seguidores o seguidos de un usuario.
class FollowListPage extends ConsumerWidget {
  const FollowListPage({
    super.key,
    required this.userId,
    required this.followers,
  });

  final int userId;

  /// `true` muestra seguidores; `false`, a quién sigue.
  final bool followers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = followers
        ? followersProvider(userId)
        : followingProvider(userId);
    return _UserListScaffold(
      title: followers ? 'Seguidores' : 'Siguiendo',
      emptyTitle: followers ? 'Aún no hay seguidores' : 'No sigue a nadie',
      emptyMessage: followers
          ? 'Cuando alguien lo siga, aparecerá aquí.'
          : 'Las personas que siga aparecerán aquí.',
      users: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
    );
  }
}

/// Personas que bloqueaste, con la opción de desbloquearlas.
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    UserSummary user,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).unblock(user.id);
      ref.invalidate(blockedProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Desbloqueaste a ${user.displayName}')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _UserListScaffold(
      title: 'Usuarios bloqueados',
      emptyTitle: 'No has bloqueado a nadie',
      emptyMessage: 'Las personas que bloquees aparecerán aquí.',
      users: ref.watch(blockedProvider),
      onRetry: () => ref.invalidate(blockedProvider),
      openProfile: false,
      trailingBuilder: (user) => TextButton(
        onPressed: () => _unblock(context, ref, user),
        child: const Text('Desbloquear'),
      ),
    );
  }
}

class _UserListScaffold extends StatelessWidget {
  const _UserListScaffold({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.users,
    required this.onRetry,
    this.openProfile = true,
    this.trailingBuilder,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final AsyncValue<PageResponse<UserSummary>> users;
  final VoidCallback onRetry;
  final bool openProfile;
  final Widget? Function(UserSummary user)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: users.when(
        loading: () => const SkeletonCards(count: 5, height: 72),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudo cargar la lista',
          onRetry: onRetry,
        ),
        data: (page) {
          if (page.content.isEmpty) {
            return EmptyState(
              icon: AppIcons.search,
              title: emptyTitle,
              message: emptyMessage,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: page.content.length,
            itemBuilder: (context, i) {
              final user = page.content[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                leading: UserAvatar(
                  name: user.displayName,
                  url: user.avatarUrl,
                ),
                title: Text(
                  user.displayName,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text('@${user.username}'),
                trailing:
                    trailingBuilder?.call(user) ??
                    (user.personalStreak > 0
                        ? IconText(
                            AppIcons.flame,
                            '${user.personalStreak}',
                            color: AppColors.peach,
                          )
                        : null),
                onTap: openProfile
                    ? () => context.push('/users/${user.id}')
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
