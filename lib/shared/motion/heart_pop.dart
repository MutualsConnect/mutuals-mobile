import 'package:flutter/material.dart';

/// Corazón de "me gusta" con rebote: crece y vuelve a su tamaño al activarse.
class HeartPop extends StatefulWidget {
  const HeartPop({
    super.key,
    required this.liked,
    this.size = 22,
    this.color = const Color(0xFFE5533D),
    this.idleColor,
  });

  final bool liked;
  final double size;
  final Color color;
  final Color? idleColor;

  @override
  State<HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<HeartPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.45,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.45,
        end: 0.9,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.9,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(HeartPop old) {
    super.didUpdateWidget(old);
    if (widget.liked && !old.liked) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: widget.liked ? widget.color : widget.idleColor,
        size: widget.size,
      ),
    );
  }
}

/// Corazón grande que aparece un instante en el centro, como el doble toque de Instagram.
class BigHeartOverlay extends StatefulWidget {
  const BigHeartOverlay({super.key, required this.trigger});

  /// Cada vez que cambia, el corazón vuelve a aparecer.
  final int trigger;

  @override
  State<BigHeartOverlay> createState() => _BigHeartOverlayState();
}

class _BigHeartOverlayState extends State<BigHeartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(BigHeartOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger) _controller.forward(from: 0);
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
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          // Crece rápido y se desvanece al final.
          final scale = Curves.elasticOut.transform((t * 1.6).clamp(0.0, 1.0));
          final opacity = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.4 + 0.9 * scale,
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFE5533D),
                size: 88,
              ),
            ),
          );
        },
      ),
    );
  }
}
