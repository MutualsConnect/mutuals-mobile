import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../application/feed_controller.dart';
import '../data/models/activity_models.dart';
import '../../../shared/motion/fade_slide_in.dart';
import '../../../shared/motion/haptics.dart';
import '../../../shared/motion/heart_pop.dart';
import '../../../shared/motion/press_scale.dart';
import '../../../shared/motion/skeleton.dart';

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
    Haptics.light();
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
      return const SkeletonCards(count: 4, height: 150);
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
                  icon: AppIcons.feed,
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
                return FadeSlideIn(
                  index: i,
                  child: _ActivityCard(
                    activity: activity,
                    onLike: () => _like(activity),
                  ),
                );
              },
            ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.activity, required this.onLike});

  final Activity activity;
  final VoidCallback onLike;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  /// Sube cada vez que se hace doble toque, para repetir el corazón grande.
  int _burst = 0;

  void _doubleTap() {
    // Como en Instagram: el doble toque da me gusta (nunca lo quita).
    if (!widget.activity.likedByMe) widget.onLike();
    Haptics.medium();
    setState(() => _burst++);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = widget.activity;
    return PressScale(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: a.fromMutual ? AppColors.glass : AppColors.glassSoft,
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
                            '${a.fromMutual ? 'Mutual · ' : ''}${timeAgo(a.createdAt)}',
                            style: text.labelSmall?.copyWith(
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(a.icon, size: 28, color: AppColors.peach),
                  ],
                ),
                const SizedBox(height: 12),
                // Doble toque sobre el texto de la novedad = me gusta, como en
                // Instagram. Solo aquí, para no retrasar los toques simples.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: _doubleTap,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      a.title,
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Action(
                      leading: HeartPop(
                        liked: a.likedByMe,
                        idleColor: AppColors.ink,
                      ),
                      label: '${a.likeCount}',
                      tooltip: a.likedByMe ? 'Quitar me gusta' : 'Me gusta',
                      onTap: widget.onLike,
                    ),
                    const SizedBox(width: 8),
                    _Action(
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.ink,
                        size: 22,
                      ),
                      label: '${a.commentCount}',
                      tooltip: 'Comentarios',
                      onTap: () => context.push(
                        '/activities/${a.id}/comments',
                        extra: a,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          BigHeartOverlay(trigger: _burst),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.leading,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final Widget leading;
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
              leading,
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
