import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../streaks/data/streak_repository.dart';
import '../data/models/social_models.dart';
import '../data/social_repository.dart';
import '../../../shared/motion/skeleton.dart';
import '../../../shared/motion/fade_slide_in.dart';
import '../../../shared/motion/press_scale.dart';

class MutualsPage extends ConsumerWidget {
  const MutualsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutuals = ref.watch(mutualsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mutuals')),
      body: mutuals.when(
        loading: () => const SkeletonCards(count: 4, height: 104),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudieron cargar tus mutuals',
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
                      icon: AppIcons.handshake,
                      title: 'Aún no tienes mutuals',
                      message: 'Busca a tus amigos y síguelos. Cuando ellos te sigan también, serán mutuals.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => FadeSlideIn(
                    index: i,
                    child: PressScale(child: _MutualTile(card: list[i])),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MutualTile extends ConsumerWidget {
  const _MutualTile({required this.card});

  final MutualCard card;

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(streakRepositoryProvider).invite(card.friend.id);
      ref.invalidate(mutualsProvider);
      ref.invalidate(sentInvitationsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Invitación enviada a ${card.friend.displayName}'),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final streak = card.streak;
    return Material(
      color: AppColors.glass,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/users/${card.friend.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                name: card.friend.displayName,
                url: card.friend.avatarUrl,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.friend.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '@${card.friend.username}',
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    _status(text, streak),
                  ],
                ),
              ),
              if (streak == null && !card.invitationPending)
                FilledButton(
                  onPressed: () => _invite(context, ref),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Invitar'),
                )
              else if (streak != null)
                Column(
                  children: [
                    const Icon(
                      AppIcons.flame,
                      size: 26,
                      color: AppColors.peach,
                    ),
                    Text(
                      '${streak.currentLength}',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
      color = AppColors.glass;
    } else if (streak.atRisk) {
      label = 'En riesgo';
      color = const Color(0x4DFF6B5B);
    } else if (streak.countedToday) {
      label = 'Hecha hoy';
      color = AppColors.glassSky;
    } else {
      label = 'Pendiente hoy';
      color = AppColors.glass;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
