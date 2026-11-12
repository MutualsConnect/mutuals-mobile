import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo provisional de Mutuals con una entrada animada.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: const Text('🔥', style: TextStyle(fontSize: 46)),
          ),
          const SizedBox(height: 16),
          Text(
            'Mutuals',
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}
