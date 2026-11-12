import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';

/// Perfil de la persona que usa la app.
class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(
            child: UserAvatar(
              name: user.displayName,
              url: user.avatarUrl,
              radius: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            '@${user.username}',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          if (user.premium)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  '⭐ Mutuals Plus',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(user.bio!, textAlign: TextAlign.center, style: text.bodyLarge),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _Stat(
                value: '${user.personalStreak}',
                label: 'Racha',
                emoji: '🔥',
              ),
              const SizedBox(width: 10),
              _Stat(value: '${user.gems}', label: 'Gemas', emoji: '💎'),
              const SizedBox(width: 10),
              _Stat(value: '${user.shields}', label: 'Escudos', emoji: '🛡️'),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Mejor racha: ${user.longestPersonalStreak}',
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Text('🏆', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Logros',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/achievements'),
          ),
          ListTile(
            leading: const Text('🎯', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Desafíos de la semana',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/challenges'),
          ),
          ListTile(
            leading: const Text('🧑‍🎨', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Mi avatar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/avatar'),
          ),
          ListTile(
            leading: const Text('💎', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Billetera',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/wallet'),
          ),
          ListTile(
            leading: const Text('💌', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Invitaciones de racha',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/invitations'),
          ),
          ListTile(
            leading: const Text('📜', style: TextStyle(fontSize: 24)),
            title: const Text(
              'Historial de rachas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/history'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.peach, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.emoji});

  final String value;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.sky,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              '$emoji $value',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
