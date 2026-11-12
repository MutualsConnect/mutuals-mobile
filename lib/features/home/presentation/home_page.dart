import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../social/data/social_repository.dart';
import '../../streaks/data/streak_repository.dart';
import '../../streaks/presentation/streak_tile.dart';

/// Inicio: tus rachas activas y las invitaciones pendientes.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(receivedInvitationsProvider);
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
            if (invitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InvitationsBanner(count: invitations.length),
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

class _InvitationsBanner extends StatelessWidget {
  const _InvitationsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sky,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/invitations'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 1
                      ? 'Tienes 1 invitación de racha'
                      : 'Tienes $count invitaciones de racha',
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
