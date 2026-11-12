import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../data/models/social_models.dart';
import '../data/social_repository.dart';

class MutualsPage extends ConsumerWidget {
  const MutualsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutuals = ref.watch(mutualsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mutuals')),
      body: mutuals.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.peach)),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudieron cargar tus mutuals',
          onRetry: () => ref.invalidate(mutualsProvider),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () => ref.refresh(mutualsProvider.future),
          child: list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyState(
                      emoji: '🤝',
                      title: 'Aún no tienes mutuals',
                      message: 'Busca a tus amigos y síguelos. Cuando ellos te sigan también, serán mutuals.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _MutualTile(card: list[i]),
                ),
        ),
      ),
    );
  }
}

class _MutualTile extends StatelessWidget {
  const _MutualTile({required this.card});

  final MutualCard card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final streak = card.streak;
    return Material(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/users/${card.friend.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(name: card.friend.displayName, url: card.friend.avatarUrl, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.friend.displayName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('@${card.friend.username}', style: text.bodySmall?.copyWith(color: AppColors.inkSoft)),
                    const SizedBox(height: 6),
                    _status(text, streak),
                  ],
                ),
              ),
              if (streak != null)
                Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 26)),
                    Text('${streak.currentLength}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(TextTheme text, StreakCard? streak) {
    final String label;
    final Color color;
    if (streak == null) {
      label = card.invitationPending ? 'Invitación enviada' : 'Sin racha';
      color = Colors.white;
    } else if (streak.atRisk) {
      label = 'En riesgo';
      color = const Color(0xFFFFB4A8);
    } else if (streak.countedToday) {
      label = 'Hecha hoy';
      color = AppColors.sky;
    } else {
      label = 'Pendiente hoy';
      color = Colors.white;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
