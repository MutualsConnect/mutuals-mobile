import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';

/// Prioridad de una notificación: las `high` también se envían como push.
enum NotificationPriority { high, low }

/// Notificación de la app (`NotificationResponse`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.createdAt,
    this.body,
    this.read = false,
    this.referenceType,
    this.referenceId,
  });

  final int id;

  /// Tipo tal como lo envía el backend, por ejemplo `STREAK_AT_RISK`.
  final String type;
  final NotificationPriority priority;
  final String title;
  final String? body;
  final bool read;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    priority: priority,
    title: title,
    body: body,
    read: read ?? this.read,
    referenceType: referenceType,
    referenceId: referenceId,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String,
        priority: json['priority'] == 'HIGH'
            ? NotificationPriority.high
            : NotificationPriority.low,
        title: json['title'] as String,
        body: json['body'] as String?,
        read: json['read'] as bool? ?? false,
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Icono que representa el tipo de aviso.
  IconData get icon => switch (type) {
    'NEW_FOLLOWER' => AppIcons.wave,
    'MUTUAL_CREATED' => AppIcons.handshake,
    'STREAK_INVITATION' => AppIcons.mail,
    'STREAK_STARTED' => AppIcons.flame,
    'INTERACTION_PENDING' => AppIcons.hourglass,
    'INTERACTION_CONFIRMED' => AppIcons.check,
    'PROXIMITY_DETECTED' => AppIcons.pin,
    'STREAK_AT_RISK' => AppIcons.warning,
    'STREAK_BROKEN' => AppIcons.broken,
    'STREAK_MILESTONE' => AppIcons.trophy,
    'SHIELD_RECEIVED' => AppIcons.gift,
    'SHIELD_USED' => AppIcons.shield,
    'CHALLENGE_ASSIGNED' || 'CHALLENGE_COMPLETED' => AppIcons.target,
    'ACHIEVEMENT_UNLOCKED' => AppIcons.medal,
    'ACTIVITY_LIKED' => AppIcons.heart,
    'ACTIVITY_COMMENTED' => AppIcons.chat,
    'WRAPPED_READY' => AppIcons.film,
    'SUBSCRIPTION' => AppIcons.star,
    'MOMENT_STARTED' => AppIcons.camera,
    _ => AppIcons.bell,
  };

  /// Pantalla a la que lleva tocar la notificación, o `null` si no hay.
  String? get route {
    final id = referenceId;
    if (id == null) return null;
    return switch (referenceType) {
      'USER' => '/users/$id',
      'STREAK' => '/streaks/$id',
      'STREAK_INVITATION' => '/invitations',
      'INTERACTION' => '/pending',
      'MOMENT' => '/moments/$id',
      _ => null,
    };
  }
}

/// Contadores para el punto rojo (`UnreadCountResponse`).
class UnreadCount {
  const UnreadCount({this.total = 0, this.high = 0, this.low = 0});

  final int total;
  final int high;
  final int low;

  factory UnreadCount.fromJson(Map<String, dynamic> json) => UnreadCount(
    total: (json['total'] as num).toInt(),
    high: (json['high'] as num).toInt(),
    low: (json['low'] as num).toInt(),
  );
}
