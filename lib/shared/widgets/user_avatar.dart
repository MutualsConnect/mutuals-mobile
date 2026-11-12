import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Avatar con la foto del usuario o, si no hay, sus iniciales.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.radius = 24});

  final String name;
  final String? url;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      _initials,
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.peach,
      foregroundImage: url == null ? null : NetworkImage(url!),
      onForegroundImageError: url == null ? null : (_, _) {},
      child: fallback,
    );
  }
}
