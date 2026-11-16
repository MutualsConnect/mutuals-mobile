import 'package:flutter/material.dart';

/// Un icono pequeño seguido de un texto (por ejemplo `+20` con una gema).
class IconText extends StatelessWidget {
  const IconText(
    this.icon,
    this.text, {
    super.key,
    this.style,
    this.color,
    this.size,
    this.trailingIcon = false,
  });

  final IconData icon;
  final String text;
  final TextStyle? style;
  final Color? color;
  final double? size;

  /// Pone el icono después del texto.
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final iconSize = size ?? (base.fontSize ?? 14) * 1.15;
    final ic = Icon(icon, size: iconSize, color: color ?? base.color);
    final label = Text(text, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: trailingIcon
          ? [Flexible(child: label), const SizedBox(width: 4), ic]
          : [ic, const SizedBox(width: 4), Flexible(child: label)],
    );
  }
}
