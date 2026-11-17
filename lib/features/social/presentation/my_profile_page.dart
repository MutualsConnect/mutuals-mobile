import 'package:flutter/material.dart';

import '../../../shared/widgets/icon_text.dart';

import '../../../core/theme/app_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../../shared/motion/animated_count.dart';

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
                child: IconText(
                  AppIcons.star,
                  'Mutuals Plus',
                  style: TextStyle(fontWeight: FontWeight.w800),
                  color: AppColors.peach,
                ),
              ),
            ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(user.bio!, textAlign: TextAlign.center, style: text.bodyLarge),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar perfil'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                value: '${user.personalStreak}',
                label: 'Racha',
                icon: AppIcons.flame,
              ),
              const SizedBox(width: 10),
              _Stat(value: '${user.gems}', label: 'Gemas', icon: AppIcons.gem),
              const SizedBox(width: 10),
              _Stat(
                value: '${user.shields}',
                label: 'Escudos',
                icon: AppIcons.shield,
              ),
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
          Glass(
            radius: 26,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    AppIcons.camera,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Recuerdos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/moments'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.film,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Mi Wrapped',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/wrapped'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.star,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: Text(
                    user.premium ? 'Mutuals Plus (activo)' : 'Mutuals Plus',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/plus'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.trophy,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Logros',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/achievements'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.target,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Desafíos de la semana',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/challenges'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.avatar,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Mi avatar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/avatar'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.gem,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Billetera',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/wallet'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.mail,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Invitaciones de racha',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/invitations'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.check,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Historial de interacciones',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/timeline'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.star,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Personalizar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/customization'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.history,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Historial de rachas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/history'),
                ),
                ListTile(
                  leading: const Icon(
                    AppIcons.settings,
                    size: 24,
                    color: AppColors.peach,
                  ),
                  title: const Text(
                    'Ajustes',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
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
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.glassSky,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.peach, size: 22),
                const SizedBox(width: 6),
                AnimatedCount(
                  value: int.tryParse(value) ?? 0,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
