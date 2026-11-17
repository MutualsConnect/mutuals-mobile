import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/motion/skeleton.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../data/interaction_repository.dart';
import '../data/models/interaction_models.dart';

/// Historial de todas tus interacciones con amigos.
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineProvider);
    final myId = ref.watch(authControllerProvider).user?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de interacciones')),
      body: timeline.when(
        loading: () => const SkeletonCards(count: 5, height: 72),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudo cargar',
          onRetry: () => ref.invalidate(timelineProvider),
        ),
        data: (page) {
          if (page.content.isEmpty) {
            return const EmptyState(
              icon: AppIcons.check,
              title: 'Aún no hay interacciones',
              message: 'Cada vez que veas a un amigo, quedará registrado aquí.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: page.content.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) =>
                _TimelineTile(interaction: page.content[i], myId: myId),
          );
        },
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.interaction, required this.myId});

  final Interaction interaction;
  final int? myId;

  String get _method => switch (interaction.method) {
    InteractionMethod.qr => 'por QR',
    InteractionMethod.proximity => 'por cercanía',
    InteractionMethod.manual => 'manual',
  };

  (String, Color) get _status => switch (interaction.status) {
    InteractionStatus.confirmed => ('Confirmada', AppColors.ink),
    InteractionStatus.pending => ('Pendiente', AppColors.inkSoft),
    InteractionStatus.expired => ('Expirada', AppColors.inkSoft),
    InteractionStatus.rejected => ('Rechazada', AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final other = interaction.initiator.id == myId
        ? (interaction.confirmer ?? interaction.initiator)
        : interaction.initiator;
    final when = interaction.confirmedAt ?? interaction.expiresAt;
    final (label, color) = _status;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: UserAvatar(name: other.displayName, url: other.avatarUrl),
      title: Text(
        other.displayName,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          _method,
          if (interaction.streakLength != null)
            'racha de ${interaction.streakLength}',
          if (when != null) formatDate(when.toLocal()),
        ].join(' · '),
      ),
      trailing: Text(
        label,
        style: text.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
