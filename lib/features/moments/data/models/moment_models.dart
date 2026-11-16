import '../../../social/data/models/social_models.dart';

enum MomentStatus { open, completed, expired }

/// La foto de una de las dos personas (`MomentPhotoResponse`).
class MomentPhoto {
  const MomentPhoto({
    required this.user,
    required this.revealed,
    required this.submittedAt,
    this.photoUrl,
    this.caption,
  });

  final UserSummary user;

  /// La foto del amigo solo se ve cuando el momento se completa; la propia siempre.
  final bool revealed;
  final String? photoUrl;
  final String? caption;
  final DateTime submittedAt;

  factory MomentPhoto.fromJson(Map<String, dynamic> json) => MomentPhoto(
    user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
    revealed: json['revealed'] as bool? ?? false,
    photoUrl: json['photoUrl'] as String?,
    caption: json['caption'] as String?,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
  );
}

/// Un momento de foto (`MomentResponse`): ambos amigos tienen unos minutos para
/// tomar una foto de lo que están haciendo y, si lo logran, la racha se confirma sola.
class Moment {
  Moment({
    required this.id,
    required this.streakId,
    required this.friend,
    required this.status,
    required this.startedByMe,
    required this.startedAt,
    required this.expiresAt,
    required int secondsLeft,
    required this.submittedByMe,
    required this.friendSubmitted,
    required this.photos,
    DateTime? receivedAt,
  }) : _secondsLeftAtReceive = secondsLeft,
       receivedAt = receivedAt ?? DateTime.now();

  final int id;
  final int streakId;
  final UserSummary friend;
  final MomentStatus status;
  final bool startedByMe;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool submittedByMe;
  final bool friendSubmitted;
  final List<MomentPhoto> photos;

  /// Cuándo se recibió del servidor. El reloj del teléfono puede estar adelantado o
  /// atrasado, así que el tiempo restante se cuenta desde este momento y no con la hora.
  final DateTime receivedAt;
  final int _secondsLeftAtReceive;

  bool get isOpen => status == MomentStatus.open;
  bool get isCompleted => status == MomentStatus.completed;

  /// Segundos que quedan ahora mismo (nunca negativos).
  int remainingSeconds({DateTime? now}) {
    if (!isOpen) return 0;
    final elapsed = (now ?? DateTime.now()).difference(receivedAt).inSeconds;
    final left = _secondsLeftAtReceive - elapsed;
    return left < 0 ? 0 : left;
  }

  /// Tu foto, si ya la subiste.
  MomentPhoto? get myPhoto {
    for (final p in photos) {
      if (p.user.id != friend.id) return p;
    }
    return null;
  }

  /// La foto de tu amigo, solo si ya se reveló.
  MomentPhoto? get friendPhoto {
    for (final p in photos) {
      if (p.user.id == friend.id && p.revealed) return p;
    }
    return null;
  }

  factory Moment.fromJson(Map<String, dynamic> json) => Moment(
    id: (json['id'] as num).toInt(),
    streakId: (json['streakId'] as num).toInt(),
    friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
    status: switch (json['status']) {
      'COMPLETED' => MomentStatus.completed,
      'EXPIRED' => MomentStatus.expired,
      _ => MomentStatus.open,
    },
    startedByMe: json['startedByMe'] as bool? ?? false,
    startedAt: DateTime.parse(json['startedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    secondsLeft: (json['secondsLeft'] as num?)?.toInt() ?? 0,
    submittedByMe: json['submittedByMe'] as bool? ?? false,
    friendSubmitted: json['friendSubmitted'] as bool? ?? false,
    photos: (json['photos'] as List? ?? const [])
        .map((e) => MomentPhoto.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
