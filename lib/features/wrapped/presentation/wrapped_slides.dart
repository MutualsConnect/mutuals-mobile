import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/wrapped_models.dart';

enum SlideKind { intro, counter, topMutual, methods, friends, empty, outro }

/// Una pantalla del Wrapped estilo historias.
class WrappedSlide {
  const WrappedSlide({
    required this.kind,
    required this.emoji,
    required this.title,
    required this.color,
    this.value,
    this.subtitle,
    this.methods = const {},
    this.friends = const [],
    this.showPlusUpsell = false,
  });

  final SlideKind kind;
  final String emoji;
  final String title;
  final Color color;

  /// Número que se anima de 0 hasta este valor (solo en `counter`).
  final int? value;
  final String? subtitle;
  final Map<String, int> methods;
  final List<FriendWrapped> friends;

  /// En el Wrapped histórico del plan gratis se invita a pasarse a Plus.
  final bool showPlusUpsell;
}

const _palette = [
  AppColors.peach,
  AppColors.sky,
  AppColors.peachLight,
  Color(0xFFFFE9C7),
];

String methodLabel(String method) => switch (method) {
  'QR' => 'Código QR',
  'PROXIMITY' => 'Cerca (GPS)',
  'MANUAL' => 'Confirmación manual',
  _ => method,
};

/// Construye las pantallas del Wrapped a partir de las estadísticas. Solo
/// incluye las que tienen algo que contar.
List<WrappedSlide> buildWrappedSlides({
  required String periodLabel,
  required WrappedStats stats,
  AllTimeWrapped? allTime,
}) {
  var i = 0;
  Color next() => _palette[i++ % _palette.length];
  final friends = allTime?.friends ?? const <FriendWrapped>[];

  final slides = <WrappedSlide>[
    WrappedSlide(
      kind: SlideKind.intro,
      emoji: '🎬',
      title: 'Tu Wrapped',
      subtitle: periodLabel,
      color: next(),
    ),
  ];

  if (stats.isEmpty && friends.isEmpty) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.empty,
        emoji: '🌱',
        title: 'Aún no hay mucho que contar',
        subtitle: 'Registra interacciones con tus mutuals y tu próximo Wrapped será increíble.',
        color: next(),
      ),
    );
    return slides;
  }

  if (stats.interactions > 0) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.counter,
        emoji: '💬',
        value: stats.interactions,
        title: stats.interactions == 1
            ? 'interacción con tus amigos'
            : 'interacciones con tus amigos',
        color: next(),
      ),
    );
  }
  if (stats.activeDays > 0) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.counter,
        emoji: '📅',
        value: stats.activeDays,
        title: stats.activeDays == 1 ? 'día activo' : 'días activo',
        color: next(),
      ),
    );
  }
  if (stats.longestStreak > 0) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.counter,
        emoji: '🔥',
        value: stats.longestStreak,
        title: 'días: tu racha más larga',
        color: next(),
      ),
    );
  }
  final top = stats.topMutualDisplayName;
  if (top != null && top.isNotEmpty) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.topMutual,
        emoji: '🤝',
        title: top,
        subtitle:
            'fue tu mutual del periodo · ${stats.topMutualInteractions} interacciones',
        color: next(),
      ),
    );
  }
  if (stats.interactionsByMethod.isNotEmpty) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.methods,
        emoji: '🧭',
        title: 'Cómo se conectaron',
        methods: stats.interactionsByMethod,
        color: next(),
      ),
    );
  }
  if (stats.challengesCompleted > 0 || stats.gemsEarned > 0) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.counter,
        emoji: '🎯',
        value: stats.challengesCompleted,
        title: stats.challengesCompleted == 1
            ? 'desafío completado'
            : 'desafíos completados',
        subtitle: '${stats.gemsEarned} 💎 ganadas',
        color: next(),
      ),
    );
  }
  if (stats.newMutuals > 0) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.counter,
        emoji: '✨',
        value: stats.newMutuals,
        title: stats.newMutuals == 1 ? 'mutual nuevo' : 'mutuals nuevos',
        subtitle: stats.shieldsGifted > 0
            ? '${stats.shieldsGifted} 🛡️ regalados'
            : null,
        color: next(),
      ),
    );
  }
  if (friends.isNotEmpty) {
    slides.add(
      WrappedSlide(
        kind: SlideKind.friends,
        emoji: '🫶',
        title: 'Tus amigos',
        friends: friends,
        showPlusUpsell: allTime != null && !allTime.fullAccess,
        color: next(),
      ),
    );
  }
  slides.add(
    WrappedSlide(
      kind: SlideKind.outro,
      emoji: '💛',
      title: 'Gracias por mantener tus amistades vivas',
      color: next(),
    ),
  );
  return slides;
}
