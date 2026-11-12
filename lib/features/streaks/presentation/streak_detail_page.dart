import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../social/data/social_repository.dart';
import '../data/models/streak_models.dart';
import '../data/streak_repository.dart';

class StreakDetailPage extends ConsumerWidget {
  const StreakDetailPage({super.key, required this.streakId});

  final int streakId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(streakDetailProvider(streakId));
    return Scaffold(
      appBar: AppBar(),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudo cargar la racha',
          onRetry: () => ref.invalidate(streakDetailProvider(streakId)),
        ),
        data: (s) => _Content(streak: s),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.streak});

  final StreakDetail streak;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  bool _busy = false;

  Future<void> _armShield() async {
    setState(() => _busy = true);
    try {
      await ref.read(streakRepositoryProvider).armShield(widget.streak.id);
      ref.invalidate(streakDetailProvider(widget.streak.id));
      ref.invalidate(mutualsProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escudo activado: tu racha está protegida 🛡️'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streak;
    final text = Theme.of(context).textTheme;
    final shields = ref.watch(authControllerProvider).user?.shields ?? 0;
    final canArm = s.isActive && !s.shieldArmed && shields > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        // El contador sube animado al abrir la pantalla.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: s.currentLength.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Column(
            children: [
              Text(
                s.isActive ? '🔥' : '🪦',
                style: const TextStyle(fontSize: 88),
              ),
              Text(
                '${value.round()}',
                style: text.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                s.currentLength == 1 ? 'día' : 'días',
                style: text.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.peachLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              UserAvatar(name: s.friend.displayName, url: s.friend.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Racha con ${s.friend.displayName}',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '@${s.friend.username}',
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              s.isActive
                  ? (s.countedToday ? '✅ Hecha hoy' : '⏳ Pendiente hoy')
                  : '💔 Terminada',
            ),
            if (s.pure) const _Chip('✨ Pura'),
            if (s.shieldArmed) const _Chip('🛡️ Escudo activo'),
            if (s.shieldsUsed > 0) _Chip('🛡️ ${s.shieldsUsed} usados'),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow('Empezó', formatDate(s.startDate)),
        if (s.lastActiveDate != null)
          _InfoRow('Última vez', daysAgo(s.lastActiveDate!)),
        if (s.endDate != null) _InfoRow('Terminó', formatDate(s.endDate!)),
        if (s.isActive) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/check-in', extra: s.friend),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Registrar hoy'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: canArm && !_busy ? _armShield : null,
            icon: const Icon(Icons.shield_outlined),
            label: Text(
              s.shieldArmed ? 'Escudo ya activo' : 'Activar escudo ($shields)',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un escudo protege la racha un día en que no se registre interacción.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.sky,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.inkSoft)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
