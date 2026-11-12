import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Hoja inferior que celebra una interacción confirmada.
Future<void> showCheckInSuccess(
  BuildContext context, {
  required String friendName,
  int? streakLength,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, t, child) => Transform.scale(scale: t, child: child),
              child: const Text('🔥', style: TextStyle(fontSize: 84)),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Racha con $friendName!',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (streakLength != null) ...[
              const SizedBox(height: 6),
              Text(
                '$streakLength ${streakLength == 1 ? 'día' : 'días'} seguidos',
                style: text.titleMedium,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('¡Genial!'),
            ),
          ],
        ),
      );
    },
  );
}
