import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../application/feed_controller.dart';
import '../data/models/activity_models.dart';

/// Novedades de tus mutuals y de la gente que sigues.
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(feedControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Si la primera página no llena la pantalla no habrá desplazamiento que cargue más.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0) {
        ref.read(feedControllerProvider.notifier).loadMore();
      }
    });
  }

  Future<void> _like(Activity activity) async {
    final error = await ref
        .read(feedControllerProvider.notifier)
        .toggleLike(activity);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    if (!feed.loading && !feed.last) _fillViewport();
    return Scaffold(
      appBar: AppBar(title: const Text('Novedades')),
      body: _body(feed),
    );
  }

  Widget _body(FeedState feed) {
    if (feed.loading && feed.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.peach),
      );
    }
    if (feed.error != null && feed.items.isEmpty) {
      return ErrorState(
        message: feed.error!,
        onRetry: ref.read(feedControllerProvider.notifier).refresh,
      );
    }
    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: ref.read(feedControllerProvider.notifier).refresh,
      child: feed.items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                EmptyState(
                  emoji: '📰',
                  title: 'Aún no hay novedades',
                  message: 'Cuando tus mutuals alcancen hitos o desbloqueen logros, lo verás aquí.',
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: feed.items.length + (feed.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i >= feed.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.peach),
                    ),
                  );
                }
                final activity = feed.items[i];
                return _ActivityCard(
                  activity: activity,
                  onLike: () => _like(activity),
                );
              },
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.onLike});

  final Activity activity;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = activity;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a.fromMutual ? AppColors.peachLight : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/users/${a.actor.id}'),
                child: UserAvatar(
                  name: a.actor.displayName,
                  url: a.actor.avatarUrl,
                  radius: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.actor.displayName,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${a.fromMutual ? '🤝 Mutual · ' : ''}${timeAgo(a.createdAt)}',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Text(a.emoji, style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.title,
            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Action(
                icon: a.likedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: a.likedByMe ? const Color(0xFFE5533D) : AppColors.ink,
                label: '${a.likeCount}',
                tooltip: a.likedByMe ? 'Quitar me gusta' : 'Me gusta',
                onTap: onLike,
              ),
              const SizedBox(width: 8),
              _Action(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.ink,
                label: '${a.commentCount}',
                tooltip: 'Comentarios',
                onTap: () =>
                    context.push('/activities/${a.id}/comments', extra: a),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
