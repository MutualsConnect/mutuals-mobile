import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';

/// Preferencias, dispositivos y eliminación de la cuenta.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _error;

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _toggle({bool? location, bool? push, bool? email, bool? mute}) =>
      _run(() async {
        await _repo.updatePreferences(
          locationSharingEnabled: location,
          pushEnabled: push,
          emailNotificationsEnabled: email,
          muteHighlights: mute,
        );
        ref.invalidate(preferencesProvider);
        await ref.read(preferencesProvider.future);
      });

  Future<void> _removeDevice(Device device) => _run(() async {
    await _repo.removeDevice(device.id);
    ref.invalidate(devicesProvider);
  });

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Se terminarán tus rachas y tu perfil se anonimiza. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await _repo.deleteAccount();
      await ref.read(authControllerProvider.notifier).logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final devices = ref.watch(devicesProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_error != null) ...[
            ErrorBanner(_error!),
            const SizedBox(height: 12),
          ],
          _Title('Notificaciones'),
          prefs.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(
              title: const Text('No pudimos cargar tus preferencias'),
              trailing: TextButton(
                onPressed: () => ref.invalidate(preferencesProvider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (p) => Column(
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones push'),
                  value: p.pushEnabled,
                  onChanged: (v) => _toggle(push: v),
                ),
                SwitchListTile(
                  title: const Text('Avisos por correo'),
                  value: p.emailNotificationsEnabled,
                  onChanged: (v) => _toggle(email: v),
                ),
                SwitchListTile(
                  title: const Text('Silenciar novedades destacadas'),
                  value: p.muteHighlights,
                  onChanged: (v) => _toggle(mute: v),
                ),
                const _Title('Privacidad'),
                SwitchListTile(
                  title: const Text('Compartir mi ubicación'),
                  subtitle: const Text(
                    'Solo para confirmar rachas por proximidad',
                  ),
                  value: p.locationSharingEnabled,
                  onChanged: (v) => _toggle(location: v),
                ),
              ],
            ),
          ),
          const _Title('Mis dispositivos'),
          devices.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const ListTile(
              title: Text('No pudimos cargar tus dispositivos'),
            ),
            data: (list) => list.isEmpty
                ? ListTile(
                    title: Text(
                      'Ninguno registrado todavía',
                      style: text.bodyMedium,
                    ),
                  )
                : Column(
                    children: [
                      for (final d in list)
                        ListTile(
                          leading: Icon(
                            d.platform == 'IOS'
                                ? Icons.phone_iphone_rounded
                                : Icons.phone_android_rounded,
                          ),
                          title: Text(
                            d.platform == 'IOS' ? 'iPhone' : 'Android',
                          ),
                          trailing: IconButton(
                            tooltip: 'Quitar dispositivo',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _removeDevice(d),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Eliminar mi cuenta'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
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

class _Title extends StatelessWidget {
  const _Title(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w900),
    ),
  );
}
