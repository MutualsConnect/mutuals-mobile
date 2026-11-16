import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// "1:42" a partir de los segundos que quedan.
String formatCountdown(int seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Anillo con la cuenta regresiva del momento. Se tiñe de rojo en los últimos segundos.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 220,
  });

  final int remaining;
  final int total;
  final double size;

  bool get _urgent => remaining <= 20;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final color = _urgent ? const Color(0xFFE5533D) : AppColors.peach;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (_, value, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(progress: value, color: color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCountdown(remaining),
                style: text.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _urgent ? color : AppColors.ink,
                ),
              ),
              Text(
                remaining == 1 ? 'segundo' : 'para la foto',
                style: text.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.glass;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arc, 0, 2 * math.pi, false, track);
    canvas.drawArc(arc, -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
