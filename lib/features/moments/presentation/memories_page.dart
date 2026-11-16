import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/motion/fade_slide_in.dart';
import '../../../shared/motion/press_scale.dart';
import '../../../shared/motion/skeleton.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/models/moment_models.dart';
import '../data/moment_repository.dart';

/// Recuerdos: los momentos que ya completaron, con las dos fotos.
class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(momentHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuerdos')),
      body: memories.when(
        loading: () => const SkeletonCards(count: 3, height: 220),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudieron cargar tus recuerdos',
          onRetry: () => ref.invalidate(momentHistoryProvider),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () async {
            ref.invalidate(momentHistoryProvider);
            await ref.read(momentHistoryProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    EmptyState(
                      emoji: '📸',
                      title: 'Aún no tienes recuerdos',
                      message: 'Cada momento que completen con un amigo se guarda aquí, con las dos fotos.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => FadeSlideIn(
                    index: i,
                    child: PressScale(child: _MemoryCard(moment: list[i])),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = moment.photos.isEmpty
        ? moment.startedAt
        : moment.photos.last.submittedAt;
    return Material(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/moments/${moment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final photo in moment.photos.take(2)) ...[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: _Thumb(url: photo.photoUrl),
                        ),
                      ),
                    ),
                    if (photo != moment.photos.take(2).last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Con ${moment.friend.displayName}',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                formatDate(date),
                style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Colors.white,
      child: Center(child: Text('📷', style: TextStyle(fontSize: 32))),
    );
    final u = url;
    if (u == null) return placeholder;
    return Image.network(
      ApiConfig.mediaUrl(u),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
