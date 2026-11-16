import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fondo de Mutuals: oscuro con dos resplandores suaves (durazno y celeste)
/// que le dan profundidad al vidrio.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-1.1, -1.05),
            radius: 1.1,
            colors: [Color(0x5CFFBE91), Color(0x00FFBE91)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.15, 1.05),
              radius: 1.0,
              colors: [Color(0x476E8BFF), Color(0x006E8BFF)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Superficie de vidrio: translúcida, con borde fino y brillo en el borde
/// superior. Con [blur] difumina lo que hay detrás (úsalo en barras y hojas,
/// no en listas largas).
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.blur = false,
    this.tint,
    this.borderRadius,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final Color? tint;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius ?? BorderRadius.circular(radius);
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        color: tint,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (blur) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: body,
      );
    }
    return ClipRRect(borderRadius: shape, child: body);
  }
}
