import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../social/data/models/social_models.dart';

/// Tarjeta de una racha activa con un amigo.
class StreakTile extends StatelessWidget {
  const StreakTile({super.key, required this.card});

  final MutualCard card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final streak = card.streak!;
    final (label, color) = streak.atRisk
        ? ('En riesgo', const Color(0xFFFFB4A8))
        : streak.countedToday
        ? ('Hecha hoy', AppColors.sky)
        : ('Pendiente hoy', Colors.white);
    return Material(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push('/streaks/${streak.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              UserAvatar(
                name: card.friend.displayName,
                url: card.friend.avatarUrl,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.friend.displayName,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    streak.shieldArmed ? '🔥🛡️' : '🔥',
                    style: const TextStyle(fontSize: 28),
                  ),
                  Text(
                    '${streak.currentLength}',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
