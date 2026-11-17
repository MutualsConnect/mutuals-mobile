import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';

typedef _Option = ({String code, String label, bool premium});

const _themes = <_Option>[
  (code: 'DEFAULT', label: 'Clásico', premium: false),
  (code: 'SUNSET', label: 'Atardecer', premium: true),
  (code: 'OCEAN', label: 'Océano', premium: true),
  (code: 'FOREST', label: 'Bosque', premium: true),
  (code: 'NEON', label: 'Neón', premium: true),
  (code: 'MIDNIGHT', label: 'Medianoche', premium: true),
];

const _fires = <_Option>[
  (code: 'CLASSIC', label: 'Clásico', premium: false),
  (code: 'BLUE', label: 'Azul', premium: true),
  (code: 'PURPLE', label: 'Morado', premium: true),
  (code: 'GOLD', label: 'Dorado', premium: true),
  (code: 'RAINBOW', label: 'Arcoíris', premium: true),
];

const _icons = <_Option>[
  (code: 'DEFAULT', label: 'Clásico', premium: false),
  (code: 'DARK', label: 'Oscuro', premium: true),
  (code: 'RETRO', label: 'Retro', premium: true),
  (code: 'GOLD', label: 'Dorado', premium: true),
];

/// Tema del perfil, estilo del fuego e ícono de la app.
class CustomizationPage extends ConsumerStatefulWidget {
  const CustomizationPage({super.key});

  @override
  ConsumerState<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends ConsumerState<CustomizationPage> {
  String? _error;
  bool _saving = false;

  Future<void> _save({String? theme, String? fireStyle, String? appIcon}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateCustomization(
            theme: theme,
            fireStyle: fireStyle,
            appIcon: appIcon,
          );
      ref.invalidate(customizationProvider);
      await ref.read(customizationProvider.future);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final custom = ref.watch(customizationProvider);
    final premium = ref.watch(authControllerProvider).user?.premium ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Personalizar')),
      body: custom.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'No se pudo cargar',
          onRetry: () => ref.invalidate(customizationProvider),
        ),
        data: (c) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (_error != null) ...[
              ErrorBanner(_error!),
              const SizedBox(height: 12),
            ],
            if (!premium)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Las opciones con candado son de Plus'),
                  trailing: TextButton(
                    onPressed: () => context.push('/plus'),
                    child: const Text('Ver Plus'),
                  ),
                ),
              ),
            _Section(
              title: 'Tema del perfil',
              options: _themes,
              selected: c.theme,
              premium: premium,
              busy: _saving,
              onPick: (code) => _save(theme: code),
            ),
            _Section(
              title: 'Estilo del fuego',
              options: _fires,
              selected: c.fireStyle,
              premium: premium,
              busy: _saving,
              onPick: (code) => _save(fireStyle: code),
            ),
            _Section(
              title: 'Ícono de la app',
              options: _icons,
              selected: c.appIcon,
              premium: premium,
              busy: _saving,
              onPick: (code) => _save(appIcon: code),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.options,
    required this.selected,
    required this.premium,
    required this.busy,
    required this.onPick,
  });

  final String title;
  final List<_Option> options;
  final String selected;
  final bool premium;
  final bool busy;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o.label),
                  avatar: o.premium && !premium
                      ? const Icon(Icons.lock_outline_rounded, size: 16)
                      : null,
                  selected: o.code == selected,
                  onSelected: busy || (o.premium && !premium)
                      ? null
                      : (_) => onPick(o.code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
