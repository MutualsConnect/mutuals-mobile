import 'package:flutter/material.dart';

/// La llama de la racha: late y se mece un poco unas cuantas veces y se queda quieta.
class AnimatedFlame extends StatefulWidget {
  const AnimatedFlame({
    super.key,
    this.size = 88,
    this.icon = Icons.local_fire_department_rounded,
    this.color = const Color(0xFFFFBE91),
    this.pulses = 4,
  });

  final double size;
  final IconData icon;
  final Color color;

  /// Cuántos latidos hace; es finito para que la pantalla pueda asentarse.
  final int pulses;

  @override
  State<AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<AnimatedFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true, count: widget.pulses * 2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.rotate(
          angle: (t - 0.5) * 0.08,
          child: Transform.scale(
            scale: 1 + 0.09 * t,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
