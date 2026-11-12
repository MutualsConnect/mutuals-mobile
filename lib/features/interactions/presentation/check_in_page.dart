import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../social/data/models/social_models.dart';
import '../../social/data/social_repository.dart';
import '../data/interaction_repository.dart';
import '../data/models/interaction_models.dart';
import 'check_in_success.dart';

/// Elige cómo registrar la interacción de hoy con un amigo.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key, required this.friend});

  final UserSummary friend;

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  bool _busy = false;
  String? _waiting;

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } on LocationException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manual() async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Cuéntale a ${widget.friend.displayName}'),
          content: TextField(
            controller: controller,
            maxLength: 140,
            decoration: const InputDecoration(
              hintText: 'Nota opcional (¿qué hicieron?)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    if (note == null) return;
    await _run(() async {
      await ref
          .read(interactionRepositoryProvider)
          .create(widget.friend.id, note: note);
      ref.invalidate(mutualsProvider);
      if (mounted) {
        _toast(
          'Enviado. ${widget.friend.displayName} debe confirmarlo en 24 h.',
        );
        context.pop();
      }
    });
  }

  Future<void> _proximity() async {
    ProximityResult? result;
    await _run(() async {
      final here = await ref.read(locationServiceProvider).current();
      result = await ref
          .read(interactionRepositoryProvider)
          .checkInByProximity(
            friendId: widget.friend.id,
            latitude: here.latitude,
            longitude: here.longitude,
          );
      ref.invalidate(mutualsProvider);
    });
    final r = result;
    if (!mounted || r == null) return;
    if (r.confirmed) {
      setState(() => _waiting = null);
      await showCheckInSuccess(
        context,
        friendName: widget.friend.displayName,
        streakLength: r.interaction?.streakLength,
      );
      if (mounted) context.pop();
    } else {
      setState(() => _waiting = r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar hoy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            children: [
              UserAvatar(
                name: friend.displayName,
                url: friend.avatarUrl,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '¿Cómo hablaron hoy con ${friend.displayName}?',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_waiting != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('⏳', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _waiting!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _Option(
            emoji: '💬',
            title: 'Confirmación manual',
            subtitle:
                'Registra la interacción y tu amigo la confirma en 24 horas.',
            onTap: _busy ? null : _manual,
          ),
          const SizedBox(height: 12),
          _Option(
            emoji: '📷',
            title: 'Escanear su código QR',
            subtitle:
                'Se confirma al instante. El código cambia cada 30 segundos.',
            onTap: _busy ? null : () => context.push('/scan'),
          ),
          const SizedBox(height: 12),
          _Option(
            emoji: '🧭',
            title: 'Mi código QR',
            subtitle:
                'Muéstrale tu código a ${friend.displayName} para que lo escanee.',
            onTap: _busy ? null : () => context.push('/qr'),
          ),
          const SizedBox(height: 12),
          _Option(
            emoji: '📍',
            title: 'Estamos juntos',
            subtitle: 'Ambos tocan este botón en 2 minutos y a menos de 100 m.',
            loading: _busy,
            onTap: _busy ? null : _proximity,
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.ink,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
