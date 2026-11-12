import '../../../social/data/models/social_models.dart';

enum InvitationStatus { pending, accepted, rejected, canceled }

InvitationStatus _invitationStatus(String raw) => switch (raw) {
      'ACCEPTED' => InvitationStatus.accepted,
      'REJECTED' => InvitationStatus.rejected,
      'CANCELED' => InvitationStatus.canceled,
      _ => InvitationStatus.pending,
    };

/// Invitación para empezar una racha (`InvitationResponse`).
class StreakInvitation {
  const StreakInvitation({
    required this.id,
    required this.inviter,
    required this.invitee,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final UserSummary inviter;
  final UserSummary invitee;
  final InvitationStatus status;
  final DateTime createdAt;

  factory StreakInvitation.fromJson(Map<String, dynamic> json) => StreakInvitation(
        id: (json['id'] as num).toInt(),
        inviter: UserSummary.fromJson(json['inviter'] as Map<String, dynamic>),
        invitee: UserSummary.fromJson(json['invitee'] as Map<String, dynamic>),
        status: _invitationStatus(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum StreakStatus { active, broken }

/// Detalle de una racha (`StreakDetailResponse`).
class StreakDetail {
  const StreakDetail({
    required this.id,
    required this.friend,
    required this.status,
    required this.currentLength,
    required this.startDate,
    this.endDate,
    this.lastActiveDate,
    this.countedToday = false,
    this.shieldArmed = false,
    this.shieldsUsed = 0,
    this.pure = false,
  });

  final int id;
  final UserSummary friend;
  final StreakStatus status;
  final int currentLength;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastActiveDate;
  final bool countedToday;
  final bool shieldArmed;
  final int shieldsUsed;

  /// Racha "pura": se mantuvo sin usar escudos.
  final bool pure;

  bool get isActive => status == StreakStatus.active;

  factory StreakDetail.fromJson(Map<String, dynamic> json) => StreakDetail(
        id: (json['id'] as num).toInt(),
        friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
        status: json['status'] == 'ACTIVE' ? StreakStatus.active : StreakStatus.broken,
        currentLength: (json['currentLength'] as num).toInt(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: _date(json['endDate']),
        lastActiveDate: _date(json['lastActiveDate']),
        countedToday: json['countedToday'] as bool? ?? false,
        shieldArmed: json['shieldArmed'] as bool? ?? false,
        shieldsUsed: (json['shieldsUsed'] as num?)?.toInt() ?? 0,
        pure: json['pure'] as bool? ?? false,
      );

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
}

/// Rachas con un amigo, actuales y pasadas (`StreakHistoryResponse`).
class StreakHistory {
  const StreakHistory({
    required this.friend,
    required this.currentlyMutual,
    required this.totalStreaks,
    required this.bestLength,
    required this.streaks,
  });

  final UserSummary friend;
  final bool currentlyMutual;
  final int totalStreaks;
  final int bestLength;
  final List<StreakDetail> streaks;

  factory StreakHistory.fromJson(Map<String, dynamic> json) => StreakHistory(
        friend: UserSummary.fromJson(json['friend'] as Map<String, dynamic>),
        currentlyMutual: json['currentlyMutual'] as bool? ?? false,
        totalStreaks: (json['totalStreaks'] as num?)?.toInt() ?? 0,
        bestLength: (json['bestLength'] as num?)?.toInt() ?? 0,
        streaks: (json['streaks'] as List? ?? const [])
            .map((e) => StreakDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
