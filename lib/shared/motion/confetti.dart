import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lluvia de confeti de la paleta de Mutuals. Se dispara una vez al aparecer.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particles = 46,
    this.duration = const Duration(milliseconds: 1800),
  });

  final int particles;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final List<_Particle> _particles = _generate(widget.particles);

  static const _colors = [
    AppColors.peach,
    AppColors.sky,
    Color(0xFFFFD166),
    Color(0xFFE5533D),
    Colors.white,
  ];

  List<_Particle> _generate(int n) {
    // Semilla fija: la misma explosión en cada ejecución, útil para las pruebas.
    final random = math.Random(7);
    return List.generate(n, (i) {
      return _Particle(
        angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.1,
        speed: 260 + random.nextDouble() * 360,
        size: 6 + random.nextDouble() * 7,
        spin: (random.nextDouble() - 0.5) * 14,
        color: _colors[random.nextInt(_colors.length)],
        round: random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    for (final p in particles) {
      // Sale disparado hacia arriba y la gravedad lo hace caer.
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + 520 * t * t;
      final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
