import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../streaks/data/streak_repository.dart';
import '../data/models/social_models.dart';
import '../data/social_repository.dart';

/// Perfil público de otro usuario, con el botón de seguir.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(userId));
    return Scaffold(
      appBar: AppBar(),
      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.peach),
        ),
        error: (e, _) => ErrorState(
          message: e is ApiException
              ? e.message
              : 'No se pudo cargar el perfil',
          onRetry: () => ref.invalidate(profileProvider(userId)),
        ),
        data: (p) => _Content(profile: p),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.profile});

  final PublicProfile profile;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(profileProvider(widget.profile.id));
    ref.invalidate(mutualsProvider);
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _inviteToStreak() async {
    setState(() => _busy = true);
    try {
      await ref.read(streakRepositoryProvider).invite(widget.profile.id);
      ref.invalidate(mutualsProvider);
      ref.invalidate(sentInvitationsProvider);
      _toast('Invitación enviada 🔥');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFollow() async {
    final repo = ref.read(socialRepositoryProvider);
    final p = widget.profile;
    setState(() => _busy = true);
    try {
      if (!p.followedByMe) {
        final result = await repo.follow(p.id);
        _refresh();
        if (result.mutual) _toast('¡Ahora son mutuals! 🎉');
      } else {
        await _unfollow(repo, p);
      }
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unfollow(SocialRepository repo, PublicProfile p) async {
    try {
      await repo.unfollow(p.id);
    } on ApiException catch (e) {
      if (e.statusCode != 409) rethrow;
      // Hay una racha activa: pedimos confirmación antes de perderla.
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Dejar de seguir?'),
          content: Text(
            'Tienes una racha activa con ${p.displayName}. Si dejas de seguirle, la perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Dejar de seguir'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await repo.unfollow(p.id, confirmStreakLoss: true);
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final text = Theme.of(context).textTheme;
    final following = p.followedByMe;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Center(
          child: UserAvatar(name: p.displayName, url: p.avatarUrl, radius: 52),
        ),
        const SizedBox(height: 14),
        Text(
          p.displayName,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          '@${p.username}',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
        ),
        if (p.isMutual)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sky,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🤝 Mutuals',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        else if (p.followsMe)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Text(
                'Te sigue',
                style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
            ),
          ),
        if (p.bio != null && p.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(p.bio!, textAlign: TextAlign.center, style: text.bodyLarge),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            _Stat(value: '${p.personalStreak}', label: 'Racha', emoji: '🔥'),
            const SizedBox(width: 10),
            _Stat(value: '${p.followers}', label: 'Seguidores'),
            const SizedBox(width: 10),
            _Stat(value: '${p.following}', label: 'Siguiendo'),
          ],
        ),
        const SizedBox(height: 24),
        following
            ? OutlinedButton(
                onPressed: _busy ? null : _toggleFollow,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.peach, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Siguiendo'),
              )
            : FilledButton(
                onPressed: _busy ? null : _toggleFollow,
                child: Text(p.followsMe ? 'Seguir también' : 'Seguir'),
              ),
        if (p.isMutual) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _inviteToStreak,
            icon: const Icon(Icons.local_fire_department_rounded),
            label: const Text('Invitar a una racha'),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.emoji});

  final String value;
  final String label;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.peachLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              '${emoji ?? ''} $value'.trim(),
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
