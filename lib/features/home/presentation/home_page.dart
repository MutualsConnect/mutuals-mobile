import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../interactions/data/interaction_repository.dart';
import '../../social/data/social_repository.dart';
import '../../streaks/data/streak_repository.dart';
import '../../streaks/presentation/streak_tile.dart';

/// Inicio: tus rachas activas y las invitaciones pendientes.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(receivedInvitationsProvider);
    ref.invalidate(pendingInteractionsProvider);
    ref.read(authControllerProvider.notifier).refreshUser();
    ref.invalidate(mutualsProvider);
    await ref.read(mutualsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final mutuals = ref.watch(mutualsProvider);
    final invitations =
        ref.watch(receivedInvitationsProvider).value ?? const [];
    final pending = ref.watch(pendingInteractionsProvider).value ?? const [];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mutuals')),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              'Hola, ${user?.displayName ?? ''} 👋',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(label: 'Gemas', value: '${user?.gems ?? 0}', icon: '💎'),
                const SizedBox(width: 12),
                _Stat(
                  label: 'Escudos',
                  value: '${user?.shields ?? 0}',
                  icon: '🛡️',
                ),
              ],
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Banner(
                emoji: '✅',
                message: pending.length == 1
                    ? '1 amigo espera tu confirmación'
                    : '${pending.length} amigos esperan tu confirmación',
                route: '/pending',
              ),
            ],
            if (invitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Banner(
                emoji: '💌',
                message: invitations.length == 1
                    ? 'Tienes 1 invitación de racha'
                    : 'Tienes ${invitations.length} invitaciones de racha',
                route: '/invitations',
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Tus rachas',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            mutuals.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.peach),
                ),
              ),
              error: (e, _) => ErrorState(
                message: e is ApiException
                    ? e.message
                    : 'No se pudieron cargar tus rachas',
                onRetry: () => ref.invalidate(mutualsProvider),
              ),
              data: (list) {
                final active = list.where((m) => m.streak != null).toList();
                if (active.isEmpty) {
                  return const EmptyState(
                    emoji: '🔥',
                    title: 'Aún no tienes rachas',
                    message: 'Ve a Mutuals e invita a un amigo para empezar tu primera racha.',
                  );
                }
                return Column(
                  children: [
                    for (final m in active) ...[
                      StreakTile(card: m),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.emoji,
    required this.message,
    required this.route,
  });

  final String emoji;
  final String message;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sky,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(label, style: text.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
