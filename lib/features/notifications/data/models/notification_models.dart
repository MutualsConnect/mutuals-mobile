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

  /// Emoji que representa el tipo de aviso.
  String get emoji => switch (type) {
    'NEW_FOLLOWER' => '👋',
    'MUTUAL_CREATED' => '🤝',
    'STREAK_INVITATION' => '💌',
    'STREAK_STARTED' => '🔥',
    'INTERACTION_PENDING' => '⏳',
    'INTERACTION_CONFIRMED' => '✅',
    'PROXIMITY_DETECTED' => '📍',
    'STREAK_AT_RISK' => '⚠️',
    'STREAK_BROKEN' => '💔',
    'STREAK_MILESTONE' => '🏆',
    'SHIELD_RECEIVED' => '🎁',
    'SHIELD_USED' => '🛡️',
    'CHALLENGE_ASSIGNED' || 'CHALLENGE_COMPLETED' => '🎯',
    'ACHIEVEMENT_UNLOCKED' => '🏅',
    'ACTIVITY_LIKED' => '❤️',
    'ACTIVITY_COMMENTED' => '💬',
    'WRAPPED_READY' => '🎬',
    'SUBSCRIPTION' => '⭐',
    _ => '🔔',
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
