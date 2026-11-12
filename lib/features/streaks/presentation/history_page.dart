import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../data/models/streak_models.dart';
import '../data/streak_repository.dart';

/// Historial de rachas agrupado por amigo.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(streakHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de rachas')),
      body: history.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar el historial',
          onRetry: () => ref.invalidate(streakHistoryProvider),
        ),
        data: (groups) => groups.isEmpty
            ? const EmptyState(
                emoji: '📜',
                title: 'Aún no hay historial',
                message: 'Tus rachas, activas y terminadas, aparecerán aquí.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _Group(group: groups[i]),
              ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final StreakHistory group;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peachLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: group.friend.displayName,
                url: group.friend.avatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.friend.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Mejor racha: ${group.bestLength} · ${group.totalStreaks} en total',
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in group.streaks)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(
                s.isActive ? '🔥' : '💔',
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(
                '${s.currentLength} ${s.currentLength == 1 ? 'día' : 'días'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                s.isActive
                    ? 'Desde ${formatDate(s.startDate)}'
                    : '${formatDate(s.startDate)} – ${s.endDate == null ? '' : formatDate(s.endDate!)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/streaks/${s.id}'),
            ),
        ],
      ),
    );
  }
}
