import '../../../social/data/models/social_models.dart';

enum InteractionMethod { manual, proximity, qr }

enum InteractionStatus { pending, confirmed, expired, rejected }

InteractionMethod _method(String raw) => switch (raw) {
      'QR' => InteractionMethod.qr,
      'PROXIMITY' => InteractionMethod.proximity,
      _ => InteractionMethod.manual,
    };

InteractionStatus _status(String raw) => switch (raw) {
      'CONFIRMED' => InteractionStatus.confirmed,
      'EXPIRED' => InteractionStatus.expired,
      'REJECTED' => InteractionStatus.rejected,
      _ => InteractionStatus.pending,
    };

/// Una interacción que cuenta para la racha (`InteractionResponse`).
class Interaction {
  const Interaction({
    required this.id,
    required this.streakId,
    required this.initiator,
    required this.confirmer,
    required this.method,
    required this.status,
    this.note,
    this.expiresAt,
    this.confirmedAt,
    this.streakLength,
  });

  final int id;
  final int streakId;
  final UserSummary initiator;
  final UserSummary confirmer;
  final InteractionMethod method;
  final InteractionStatus status;
  final String? note;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;

  /// Largo de la racha tras confirmar esta interacción.
  final int? streakLength;

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: (json['id'] as num).toInt(),
        streakId: (json['streakId'] as num).toInt(),
        initiator: UserSummary.fromJson(json['initiator'] as Map<String, dynamic>),
        confirmer: UserSummary.fromJson(json['confirmer'] as Map<String, dynamic>),
        method: _method(json['method'] as String),
        status: _status(json['status'] as String),
        note: json['note'] as String?,
        expiresAt: _time(json['expiresAt']),
        confirmedAt: _time(json['confirmedAt']),
        streakLength: (json['streakLength'] as num?)?.toInt(),
      );

  static DateTime? _time(Object? v) => v == null ? null : DateTime.parse(v as String);
}

/// Mi código QR rotativo (`QrCodeResponse`); vence cada 30 segundos.
class QrCode {
  const QrCode({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  factory QrCode.fromJson(Map<String, dynamic> json) => QrCode(
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

/// Resultado del check-in por proximidad.
class ProximityResult {
  const ProximityResult({required this.confirmed, required this.message, this.interaction});

  /// `true` si el amigo también hizo check-in y la interacción quedó confirmada;
  /// `false` si falta que él lo haga.
  final bool confirmed;
  final String message;
  final Interaction? interaction;

  factory ProximityResult.fromJson(Map<String, dynamic> json) => ProximityResult(
        confirmed: json['status'] == 'CONFIRMED',
        message: json['message'] as String? ?? '',
        interaction: json['interaction'] == null
            ? null
            : Interaction.fromJson(json['interaction'] as Map<String, dynamic>),
      );
}
