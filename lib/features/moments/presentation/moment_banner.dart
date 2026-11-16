import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/motion/press_scale.dart';
import '../data/models/moment_models.dart';
import '../data/moment_repository.dart';
import 'countdown_ring.dart';

/// Aviso en el inicio cuando hay un momento de foto abierto, con su cuenta regresiva.
/// No ocupa espacio si no hay ninguno.
class MomentBanner extends ConsumerStatefulWidget {
  const MomentBanner({super.key});

  @override
  ConsumerState<MomentBanner> createState() => _MomentBannerState();
}

class _MomentBannerState extends ConsumerState<MomentBanner>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true, count: 8);

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moments = ref.watch(activeMomentsProvider).value ?? const <Moment>[];
    final open = moments
        .where((m) => m.isOpen && m.remainingSeconds() > 0)
        .toList();
    if (open.isEmpty) return const SizedBox.shrink();
    // Primero los que esperan tu foto.
    open.sort(
      (a, b) => (a.submittedByMe ? 1 : 0).compareTo(b.submittedByMe ? 1 : 0),
    );
    final m = open.first;
    final String title;
    if (!m.submittedByMe) {
      title = m.startedByMe
          ? '¡Sube tu foto!'
          : '¡${m.friend.displayName} lanzó un momento!';
    } else {
      title = 'Esperando la foto de ${m.friend.displayName}';
    }
    final urgent = m.remainingSeconds() <= 20;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PressScale(
        child: Material(
          color: urgent && !m.submittedByMe
              ? const Color(0xFFFFB4A8)
              : AppColors.peach,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => context.push('/moments/${m.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.18).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: const Text('📸', style: TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          m.submittedByMe
                              ? 'Tu foto ya salió'
                              : 'Toca para tomar la foto',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatCountdown(m.remainingSeconds()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
