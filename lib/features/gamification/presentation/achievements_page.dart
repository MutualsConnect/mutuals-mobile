import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/gamification_repository.dart';
import '../data/models/gamification_models.dart';

/// Catálogo de logros con tu progreso.
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: achievements.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudieron cargar los logros',
          onRetry: () => ref.invalidate(achievementsProvider),
        ),
        data: (list) {
          final unlocked = list.where((a) => a.unlocked).length;
          return RefreshIndicator(
            color: AppColors.ink,
            onRefresh: () async {
              ref.invalidate(achievementsProvider);
              await ref.read(achievementsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                _Progress(unlocked: unlocked, total: list.length),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const EmptyState(emoji: '🏆', title: 'Aún no hay logros')
                else
                  for (final a in list) ...[
                    _AchievementCard(achievement: a),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unlocked de $total desbloqueados',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : unlocked / total,
              minHeight: 10,
              color: AppColors.peach,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = achievement;
    return Opacity(
      opacity: a.unlocked ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: a.unlocked ? AppColors.peachLight : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Text(
              a.unlocked ? a.emoji : '🔒',
              style: const TextStyle(fontSize: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.description,
                    style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                  ),
                  if (a.unlocked && a.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Desbloqueado el ${formatDate(a.unlockedAt!)}',
                      style: text.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            if (a.rewardGems > 0)
              Text(
                '+${a.rewardGems} 💎',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
          ],
        ),
      ),
    );
  }
}
