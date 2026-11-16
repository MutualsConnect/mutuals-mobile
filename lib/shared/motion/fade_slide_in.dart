import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Entrada suave: el contenido aparece subiendo un poco. Con [index] las
/// listas se animan escalonadas, una tarjeta tras otra.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 22,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;

  /// Posición en la lista; solo las primeras se escalonan para no esperar de más.
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    // El retraso va dentro de la misma animación (sin temporizadores), así las
    // pruebas y la pantalla se asientan sin esperas pendientes.
    final delay = Duration(milliseconds: 60 * math.min(widget.index, 8));
    final total = delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}
