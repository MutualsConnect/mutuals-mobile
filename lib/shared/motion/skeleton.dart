import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bloque gris con un brillo que lo recorre: se muestra mientras carga el
/// contenido, en lugar de una ruedita girando.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * t, 0),
              end: Alignment(-0.5 + 3 * t, 0),
              colors: [
                AppColors.peachLight.withValues(alpha: 0.55),
                AppColors.peachLight.withValues(alpha: 0.95),
                AppColors.peachLight.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lista de tarjetas esqueleto, con la forma de una tarjeta de racha o de novedad.
class SkeletonCards extends StatelessWidget {
  const SkeletonCards({
    super.key,
    this.count = 3,
    this.height = 110,
    this.padding = const EdgeInsets.all(20),
  });

  final int count;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            SkeletonBox(width: double.infinity, height: height, radius: 24),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
